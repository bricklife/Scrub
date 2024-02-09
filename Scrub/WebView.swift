//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import AsyncAlgorithms
import ScratchWebKit
import ScratchLinkKit

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        let viewController = ScratchWebViewController()
        viewController.delegate = context.coordinator
        
        context.coordinator.bind(viewModel: viewModel, viewController: viewController)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScratchWebViewController, context: Context) {
    }
}

extension WebView {
    
    @MainActor
    class Coordinator: NSObject, ScratchWebViewControllerDelegate {
        
        private var eventChannel: AsyncChannel<WebViewModel.Event>?
        
        func bind(viewModel: WebViewModel, viewController: ScratchWebViewController) {
            viewController.$url.receive(on: DispatchQueue.main).assign(to: &viewModel.$url)
            viewController.$isLoading.receive(on: DispatchQueue.main).assign(to: &viewModel.$isLoading)
            viewController.$estimatedProgress.receive(on: DispatchQueue.main).assign(to: &viewModel.$estimatedProgress)
            viewController.$canGoBack.receive(on: DispatchQueue.main).assign(to: &viewModel.$canGoBack)
            viewController.$canGoForward.receive(on: DispatchQueue.main).assign(to: &viewModel.$canGoForward)
            
            let inputChannel = viewModel.inputChannel
            Task {
                for await input in inputChannel {
                    switch input {
                    case .load(url: let url):
                        viewController.load(url: url)
                    case .goBack:
                        viewController.goBack()
                    case .goForward:
                        viewController.goForward()
                    case .reload:
                        viewController.reload()
                    case .stopLoading:
                        viewController.stopLoading()
                    }
                }
            }
            
            self.eventChannel = viewModel.eventChannel
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, decidePolicyFor url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void) {
#if DEBUG
            decisionHandler(.allow)
#else
            if url.isScratchSite || url.isFileURL || isScratchEditor {
                decisionHandler(.allow)
            } else {
                decisionHandler(.deny)
            }
#endif
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, didDownloadFileAt url: URL) {
            Task { @MainActor in
                let vc = UIDocumentPickerViewController(forExporting: [url])
                vc.shouldShowFileExtensions = true
                viewController.present(vc, animated: true)
            }
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, didFail error: Error) {
            Task {
                switch error as? ScratchWebViewError {
                case let .forbiddenAccess(url: url):
                    await eventChannel?.send(.forbiddenAccess(url))
                case .none:
                    await eventChannel?.send(.error(error))
                }
            }
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, canStartScratchLinkSessionType type: SessionType) -> Bool {
#if DEBUG
            return true
#else
            switch type {
            case .ble:
                return true
            case .bt:
                return false
            }
#endif
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, didStartScratchLinkSessionType type: SessionType) {
            Task {
                if type == .bt {
                    await eventChannel?.send(.openingBluetoothSession)
                }
            }
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, didFailStartingScratchLinkSession type: SessionType, error: SessionError) {
            Task {
                switch error {
                case .unavailable:
                    await eventChannel?.send(.notSupportedExtension)
                case .bluetoothIsPoweredOff:
                    await eventChannel?.send(.error(error))
                case .bluetoothIsUnauthorized:
                    await eventChannel?.send(.unauthorizedBluetooth)
                case .bluetoothIsUnsupported:
                    await eventChannel?.send(.error(error))
                case .other(error: let error):
                    await eventChannel?.send(.error(error))
                }
            }
        }
    }
}

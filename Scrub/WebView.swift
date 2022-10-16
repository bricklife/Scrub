//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import ScratchWebKit
import ScratchLink

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var alertController: AlertController
    
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator(alertController: alertController, preferences: preferences)
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
        
        private let alertController: AlertController
        private let preferences: Preferences
        
        init(alertController: AlertController, preferences: Preferences) {
            self.alertController = alertController
            self.preferences = preferences
        }
        
        func bind(viewModel: WebViewModel, viewController: ScratchWebViewController) {
            viewController.$url.assign(to: &viewModel.$url)
            viewController.$isLoading.assign(to: &viewModel.$isLoading)
            viewController.$estimatedProgress.assign(to: &viewModel.$estimatedProgress)
            viewController.$canGoBack.assign(to: &viewModel.$canGoBack)
            viewController.$canGoForward.assign(to: &viewModel.$canGoForward)
            
            let inputsChannel = viewModel.inputsChannel
            Task {
                for await inputs in inputsChannel {
                    switch inputs {
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
            Task { @MainActor in
                switch error as? ScratchWebViewError {
                case let .forbiddenAccess(url: url):
                    alertController.showAlert(forbiddenAccess: Text("This app can only open the official Scratch website or any Scratch Editor."), url: url)
                case .none:
                    alertController.showAlert(error: error)
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
            Task { @MainActor in
                if type == .bt, !preferences.didShowBluetoothParingDialog {
                    alertController.showAlert(howTo: Text("Please pair your Bluetooth device on Settings app before using this extension.")) { [weak self] in
                        self?.preferences.didShowBluetoothParingDialog = true
                    }
                }
            }
        }
        
        nonisolated func scratchWebViewController(_ viewController: ScratchWebViewController, didFailStartingScratchLinkSession type: SessionType, error: SessionError) {
            Task { @MainActor in
                switch error {
                case .unavailable:
                    alertController.showAlert(sorry: Text("This extension is not supported🙇🏻"))
                case .bluetoothIsPoweredOff:
                    alertController.showAlert(error: error)
                case .bluetoothIsUnauthorized:
                    alertController.showAlert(unauthorized: Text("Bluetooth"))
                case .bluetoothIsUnsupported:
                    alertController.showAlert(error: error)
                case .other(error: let error):
                    alertController.showAlert(error: error)
                }
            }
        }
    }
}

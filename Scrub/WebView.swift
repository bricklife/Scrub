//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import Combine
import ScratchWebKit
import ScratchLink

enum WebViewError: Error {
    case invalidUrl
}

extension WebViewError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("Invalid URL", comment: "Invalid URL")
        }
    }
}

extension URL {
    var isScratchSite: Bool {
        let normalizedHost = "." + (host ?? "")
        let scratchHosts = [
            ".scratch.mit.edu",
            ".scratch-wiki.info",
            ".scratchfoundation.org",
            ".scratchjr.org",
        ]
        return scratchHosts.contains(where: normalizedHost.hasSuffix(_:))
    }
}

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    @Binding var url: URL?
    
    @EnvironmentObject private var alertController: AlertController
    
    private let webViewController = ScratchWebViewController()
    
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        webViewController.delegate = context.coordinator
        
        if let url = url, url.scheme != "file" {
            webViewController.load(url: url)
        } else if let url = viewModel.home {
            webViewController.load(url: url)
        } else {
            alertController.showAlert(error: WebViewError.invalidUrl)
        }
        
        return webViewController
    }
    
    func updateUIViewController(_ uiViewController: ScratchWebViewController, context: Context) {
    }
}

extension WebView {
    
    class Coordinator: NSObject, ScratchWebViewControllerDelegate {
        
        private let parent : WebView
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(_ parent: WebView) {
            self.parent = parent
            
            parent.viewModel.inputs.sink { (inputs) in
                switch inputs {
                case .goHome:
                    if let url = parent.viewModel.home {
                        parent.webViewController.load(url: url)
                    } else {
                        parent.alertController.showAlert(error: WebViewError.invalidUrl)
                    }
                case .goBack:
                    parent.webViewController.goBack()
                case .goForward:
                    parent.webViewController.goForward()
                case .load(url: let url):
                    parent.webViewController.load(url: url)
                case .reload:
                    parent.webViewController.reload()
                case .stopLoading:
                    parent.webViewController.stopLoading()
                }
            }.store(in: &cancellables)
            
            parent.webViewController.$url.sink { (url) in
                DispatchQueue.main.async {
                    parent.url = url
                }
            }.store(in: &cancellables)
            
            parent.webViewController.$isLoading.assign(to: &parent.viewModel.$isLoading)
            parent.webViewController.$estimatedProgress.assign(to: &parent.viewModel.$estimatedProgress)
            parent.webViewController.$canGoBack.assign(to: &parent.viewModel.$canGoBack)
            parent.webViewController.$canGoForward.assign(to: &parent.viewModel.$canGoForward)
        }
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, decidePolicyFor url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void) {
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
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, didDownloadFileAt url: URL) {
            let vc = UIDocumentPickerViewController(forExporting: [url])
            vc.shouldShowFileExtensions = true
            viewController.present(vc, animated: true)
        }
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, didFail error: Error) {
            switch error as? ScratchWebViewError {
            case let .forbiddenAccess(url: url):
                parent.alertController.showAlert(forbiddenAccess: Text("This app can only open the official Scratch website or any Scratch Editor."), url: url)
            case .none:
                parent.alertController.showAlert(error: error)
            }
        }
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, canStartScratchLinkSessionType type: SessionType) -> Bool {
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
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, didStartScratchLinkSessionType type: SessionType) {
            if type == .bt, parent.viewModel.shouldShowBluetoothParingDialog {
                parent.alertController.showAlert(howTo: Text("Please pair your Bluetooth device on Settings app before using this extension.")) { [weak self] in
                    self?.parent.viewModel.didShowBluetoothParingDialog()
                }
            }
        }
        
        func scratchWebViewController(_ viewController: ScratchWebViewController, didFailStartingScratchLinkSession type: SessionType, error: SessionError) {
            switch error {
            case .unavailable:
                self.parent.alertController.showAlert(sorry: Text("This extension is not supported🙇🏻"))
            case .bluetoothIsPoweredOff:
                self.parent.alertController.showAlert(error: error)
            case .bluetoothIsUnauthorized:
                self.parent.alertController.showAlert(unauthorized: Text("Bluetooth"))
            case .bluetoothIsUnsupported:
                self.parent.alertController.showAlert(error: error)
            case .other(error: let error):
                self.parent.alertController.showAlert(error: error)
            }
        }
    }
}

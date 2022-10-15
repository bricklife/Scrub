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

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var alertController: AlertController
    
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        let webViewController = ScratchWebViewController()
        
        viewModel.preferences = preferences
        viewModel.setup(webViewController: webViewController)
        
        webViewController.delegate = context.coordinator
        
        return webViewController
    }
    
    func updateUIViewController(_ uiViewController: ScratchWebViewController, context: Context) {
    }
}

extension WebView {
    
    class Coordinator: NSObject, ScratchWebViewControllerDelegate {
        
        private let parent : WebView
        
        init(_ parent: WebView) {
            self.parent = parent
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

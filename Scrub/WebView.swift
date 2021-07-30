//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import Combine
import ScratchWebKit

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

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    @Binding var url: URL?
    
    @EnvironmentObject private var alertController: AlertController
    
    private let webViewController = ScratchWebViewController()
    
    func makeCoordinator() -> WebView.Coodinator {
        return Coodinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        webViewController.delegate = context.coordinator
        
        if let url = url, url.scheme != "file" {
            webViewController.load(url: url)
        } else if let url = viewModel.homeUrl {
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
    
    class Coodinator: NSObject, ScratchWebViewControllerDelegate {
        
        private let parent : WebView
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(_ parent: WebView) {
            self.parent = parent
            
            parent.viewModel.inputs.sink { (inputs) in
                switch inputs {
                case .goHome:
                    if let url = parent.viewModel.homeUrl {
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
        
        func decidePolicyFor(url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void) {
            #if DEBUG
            decisionHandler(.allow)
            #else
            let isScratchSite = url.host == "scratch.mit.edu"
            let isLocal = url.scheme == "file"
            if isScratchSite || isLocal || isScratchEditor {
                decisionHandler(.allow)
            } else {
                decisionHandler(.deny)
            }
            #endif
        }
        
        func didDownloadFile(at url: URL) {
            let vc = UIDocumentPickerViewController(forExporting: [url])
            vc.shouldShowFileExtensions = true
            parent.webViewController.present(vc, animated: true)
        }
        
        func didStartSession(type: SessionType) {
            if type == .bt, parent.viewModel.shouldShowBluetoothParingDialog {
                parent.alertController.showAlert(howTo: Text("Please pair your Bluetooth device on Settings app before using this extension.")) { [weak self] in
                    self?.parent.viewModel.didShowBluetoothParingDialog()
                }
            }
        }
        
        func didFail(error: Error) {
            switch error as? ScratchWebViewError {
            case let .forbiddenAccess(url: url):
                parent.alertController.showAlert(forbiddenAccess: Text("This app can only open the official Scratch website or any Scratch Editor."), url: url)
            case .none:
                parent.alertController.showAlert(error: error)
            }
        }
        
        func canStartSession(type: SessionType) -> Bool {
            #if DEBUG
            return true
            #else
            switch type {
            case .ble:
                return true
            case .bt:
                DispatchQueue.main.async {
                    self.parent.alertController.showAlert(sorry: Text("This extension is not supported🙇🏻"))
                }
                return false
            }
            #endif
        }
        
        func didFailStartingSession(type: SessionType, error: Error) {
            switch error as? BluetoothError {
            case .poweredOff:
                break
            case .unauthorized:
                parent.alertController.showAlert(error: error) // TODO:
            case .unsupported:
                parent.alertController.showAlert(error: error) // TODO:
            case .none:
                parent.alertController.showAlert(error: error)
            }
        }
    }
}

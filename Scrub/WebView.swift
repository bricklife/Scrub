//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import Combine
import ScratchWebKit

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    private let webViewController = ScratchWebViewController()
    
    func makeCoordinator() -> WebView.Coodinator {
        print(#function)
        return Coodinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        print(#function)
        webViewController.delegate = context.coordinator
        webViewController.load(url: viewModel.initialUrl)
        return webViewController
    }
    
    func updateUIViewController(_ uiViewController: ScratchWebViewController, context: Context) {
        print(#function)
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
                    parent.webViewController.load(url: parent.viewModel.homeUrl)
                case .goBack:
                    parent.webViewController.goBack()
                case .goForward:
                    parent.webViewController.goForward()
                case .load(url: let url):
                    parent.webViewController.load(url: url)
                }
            }.store(in: &cancellables)
        }
        
        func didDownloadFile(at url: URL) {
            let vc = UIDocumentPickerViewController(forExporting: [url])
            vc.shouldShowFileExtensions = true
            parent.webViewController.present(vc, animated: true)
        }
    }
}

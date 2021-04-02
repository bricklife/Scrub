//
//  WebView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import ScratchWebKit

struct WebView: UIViewControllerRepresentable {
    
    let url: URL
    
    private let webViewController = ScratchWebViewController()
    
    func makeCoordinator() -> WebView.Coodinator {
        print(#function)
        return Coodinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScratchWebViewController {
        print(#function)
        webViewController.delegate = context.coordinator
        webViewController.load(url: url)
        return webViewController
    }
    
    func updateUIViewController(_ uiViewController: ScratchWebViewController, context: UIViewControllerRepresentableContext<WebView>) {
        print(#function)
    }
}

extension WebView {
    
    class Coodinator: NSObject, ScratchWebViewControllerDelegate {
        
        private let parent : WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func didDownloadFile(at url: URL) {
            let vc = UIDocumentPickerViewController(forExporting: [url])
            vc.shouldShowFileExtensions = true
            parent.webViewController.present(vc, animated: true)
        }
    }
}

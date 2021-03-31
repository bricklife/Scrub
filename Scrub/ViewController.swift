//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import UIKit
import WebKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private let scratchLink = ScratchLink()
    private let blobDownloader = BlobDownloader()
    
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scratchLink.setup(configuration: webView.configuration)
        scratchLink.webView = webView
        
        blobDownloader.setup(configuration: webView.configuration)
        blobDownloader.webView = webView
        blobDownloader.downloadCompletion = { [weak self] (url) in
            let vc: UIDocumentPickerViewController
            if #available(iOS 14.0, *) {
                vc = UIDocumentPickerViewController(forExporting: [url])
            } else {
                vc = UIDocumentPickerViewController(url: url, in: .exportToService)
            }
            vc.shouldShowFileExtensions = true
            self?.present(vc, animated: true)
        }
        
        webView.publisher(for: \.url).sink() { [weak self] (url) in
            if url != nil, self?.webView.isLoading == false {
                self?.setStyles()
            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
        
        let url = URL(string: "https://scratch.mit.edu/projects/editor/")!
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func setStyles() {
        webView.evaluateJavaScript("document.getElementsByClassName('blocklyToolboxDiv').length > 0") { [weak self] (result, error) in
            let isScratchEditor = result as? Bool ?? false
            print("isScratchEditor:", isScratchEditor)
            if isScratchEditor {
                self?.webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
                self?.webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
            } else {
                self?.webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='auto'")
                self?.webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='inherit'")
            }
        }
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("Requested", navigationAction.request)
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.scheme == "blob" {
            blobDownloader.downloadBlob()
            decisionHandler(.cancel)
            return
        }
        
        scratchLink.closeAllSessions()
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setStyles()
    }
}

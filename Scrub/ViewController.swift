//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private let scratchLink = ScratchLink()
    private let blobDownloader = BlobDownloader()
    
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
        
        webView.navigationDelegate = self
        
        let url = URL(string: "https://scratch.mit.edu/projects/editor/")!
        let request = URLRequest(url: url)
        webView.load(request)
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
        guard let url = webView.url else { return }
        
        let isEditor = url.absoluteString.hasPrefix("https://scratch.mit.edu/projects/")
        if isEditor {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
        }
    }
}

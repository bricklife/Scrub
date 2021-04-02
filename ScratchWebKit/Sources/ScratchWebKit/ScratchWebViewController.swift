//
//  ScratchWebViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/02.
//

import UIKit
import WebKit
import Combine

public class ScratchWebViewController: UIViewController {
    
    private var webView: WKWebView!
    
    private let scratchLink = ScratchLink()
    private let blobDownloader = BlobDownloader()
    
    private var cancellables: Set<AnyCancellable> = []
    
    public weak var delegate: ScratchWebViewControllerDelegate?
    
    @Published public private(set) var url: URL? = nil
    @Published public private(set) var isLoading: Bool = false
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.dataDetectorTypes = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        view = webView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        scratchLink.setup(webView: webView)
        blobDownloader.setup(webView: webView)
        
        webView.publisher(for: \.url).assign(to: \.url, on: self).store(in: &cancellables)
        webView.publisher(for: \.isLoading).assign(to: \.isLoading, on: self).store(in: &cancellables)
        
        $url.compactMap({$0}).sink() { [weak self] (url) in
            print("url:", url)
            if self?.webView.isLoading == false {
                self?.changeWebViewStyles()
            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
    }
    
    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func changeWebViewStyles() {
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

extension ScratchWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("Requested", navigationAction.request)
        
        if let url = navigationAction.request.url, url.scheme == "blob" {
            blobDownloader.downloadBlob { [weak self] (url) in
                self?.delegate?.didDownloadFile(at: url)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        scratchLink.closeAllSessions()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        changeWebViewStyles()
    }
}

@objc public protocol ScratchWebViewControllerDelegate {
    @objc func didDownloadFile(at url: URL)
}

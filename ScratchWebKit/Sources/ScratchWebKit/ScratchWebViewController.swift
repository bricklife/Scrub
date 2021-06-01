//
//  ScratchWebViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/02.
//

import UIKit
import WebKit
import Combine

enum ScratchWebViewError: Error {
    case forbiddenAccess
}

extension ScratchWebViewError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .forbiddenAccess:
            return NSLocalizedString("Not allowed to access this URL", bundle: Bundle.module, comment: "Not allowed to access this URL")
        }
    }
}

public class ScratchWebViewController: UIViewController {
    
    private let webView: WKWebView
    
    private let scratchLink = ScratchLink()
    private var downloadingUrl: URL? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    public weak var delegate: ScratchWebViewControllerDelegate?
    
    @Published public private(set) var url: URL? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var estimatedProgress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    
    public init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.dataDetectorTypes = []
        
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = webView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        scratchLink.setup(webView: webView)
        scratchLink.delegate = self
        
        webView.publisher(for: \.url).assign(to: &$url)
        webView.publisher(for: \.isLoading).assign(to: &$isLoading)
        webView.publisher(for: \.canGoBack).assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward).assign(to: &$canGoForward)
        webView.publisher(for: \.estimatedProgress).assign(to: &$estimatedProgress)
        
        $url.compactMap({$0}).sink() { [weak self] (url) in
            if self?.webView.isLoading == false {
                self?.didChangeUrl(url)
            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    private func didChangeUrl(_ url: URL) {
        detectScratchEditor { [weak self] (isScratchEditor) in
            self?.delegate?.decidePolicyFor(url: url, isScratchEditor: isScratchEditor) { (policy) in
                switch policy {
                case .allow:
                    self?.webView.isUserInteractionEnabled = true
                    self?.webView.alpha = 1.0
                    self?.changeWebViewStyle(isScratchEditor: isScratchEditor)
                case .deny:
                    self?.webView.isUserInteractionEnabled = false
                    self?.webView.alpha = 0.4
                    self?.delegate?.didFail(error: ScratchWebViewError.forbiddenAccess)
                }
            }
        }
    }
    
    private func detectScratchEditor(completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript("document.getElementsByClassName('blocklyToolboxDiv').length > 0") { (result, error) in
            let isScratchEditor = result as? Bool ?? false
            completion(isScratchEditor)
        }
    }
    
    private func changeWebViewStyle(isScratchEditor: Bool) {
        if isScratchEditor {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
        } else {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='auto'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='inherit'")
        }
    }
}

extension ScratchWebViewController {
    
    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    public func goBack() {
        webView.goBack()
    }
    
    public func goForward() {
        webView.goForward()
    }
    
    public func reload() {
        webView.reload()
    }
    
    public func stopLoading() {
        webView.stopLoading()
    }
}

extension ScratchWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        scratchLink.closeAllSessions()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            didChangeUrl(url)
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.didFail(error: error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.didFail(error: error)
    }
}

extension ScratchWebViewController: WKDownloadDelegate {
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
        self.downloadingUrl = url
        completionHandler(url)
    }
    
    public func downloadDidFinish(_ download: WKDownload) {
        if let url = downloadingUrl {
            self.downloadingUrl = nil
            delegate?.didDownloadFile(at: url)
        }
    }
    
    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        delegate?.didFail(error: error)
    }
}

extension ScratchWebViewController: ScratchLinkDelegate {
    
    public func didStartSession(type: SessionType) {
        delegate?.didStartSession(type: type)
    }
    
    public func didFailStartingSession(type: SessionType, error: Error) {
        delegate?.didFail(error: error)
    }
}

@objc public enum WebFilterPolicy: Int {
    case allow
    case deny
}

@objc public protocol ScratchWebViewControllerDelegate {
    @objc func decidePolicyFor(url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void)
    @objc func didDownloadFile(at url: URL)
    @objc func didStartSession(type: SessionType)
    @objc func didFail(error: Error)
}

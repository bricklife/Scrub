//
//  ScratchWebViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/02.
//

import UIKit
import WebKit
import Combine

public enum ScratchWebViewError: Error {
    case forbiddenAccess(url: URL)
}

extension ScratchWebViewError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .forbiddenAccess:
            return NSLocalizedString("Not allowed to access this URL", bundle: Bundle.module, comment: "Not allowed to access this URL")
        }
    }
}

public class ScratchWebViewController: WebViewController {
    
    public weak var delegate: ScratchWebViewControllerDelegate?
    
    private let scratchLink = ScratchLink()
    private var downloadingUrl: URL? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var sizeConstraints: [NSLayoutConstraint] = []
    
    public override init() {
        super.init()
        
        scratchLink.setup(webView: webView)
        scratchLink.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        self.view = UIView(frame: .zero)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        updateSizeConstraints(multiplier: 1)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        $url.compactMap({$0}).sink() { [weak self] (url) in
            if self?.webView.isLoading == false {
                self?.didChangeUrl(url)
            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    public override func viewWillLayoutSubviews() {
        let multiplier = max(1.0, 1024.0 / view.bounds.width)
        updateSizeConstraints(multiplier: multiplier)
        webView.transform = CGAffineTransform(scaleX: 1.0 / multiplier, y: 1.0 / multiplier)
    }
    
    private func updateSizeConstraints(multiplier: CGFloat) {
        NSLayoutConstraint.deactivate(sizeConstraints)
        self.sizeConstraints = [
            webView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier),
            webView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier),
        ]
        NSLayoutConstraint.activate(sizeConstraints)
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
                    self?.delegate?.didFail(error: ScratchWebViewError.forbiddenAccess(url: url))
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
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(atPath: url.path)
        }
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
    
    public func canStartSession(type: SessionType) -> Bool {
        return delegate?.canStartScratchLinkSession(type: type) ?? true
    }
    
    public func didStartSession(type: SessionType) {
        delegate?.didStartScratchLinkSession(type: type)
    }
    
    public func didFailStartingSession(type: SessionType, error: SessionError) {
        delegate?.didFailStartingScratchLinkSession(type: type, error: error)
    }
}

public enum WebFilterPolicy {
    case allow
    case deny
}

public protocol ScratchWebViewControllerDelegate: AnyObject {
    func decidePolicyFor(url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void)
    func didDownloadFile(at url: URL)
    func didFail(error: Error)
    func canStartScratchLinkSession(type: SessionType) -> Bool
    func didStartScratchLinkSession(type: SessionType)
    func didFailStartingScratchLinkSession(type: SessionType, error: SessionError)
}

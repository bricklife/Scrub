//
//  WebViewController.swift
//  Scrub
//
//
//  Created by Shinichiro Oba on 2021/07/23.
//

import UIKit
import WebKit
import Combine

public class WebViewController: UIViewController {
    
    private let webView: WKWebView
    
    private var cancellables: Set<AnyCancellable> = []
    
    public weak var delegate: WebViewControllerDelegate?
    
    @Published public private(set) var url: URL? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var estimatedProgress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    
    private var queue: [UIViewController] = []
    
    public init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.dataDetectorTypes = []
        
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(webView: WKWebView) {
        self.webView = webView
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        self.view = webView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.publisher(for: \.url).assign(to: &$url)
        webView.publisher(for: \.isLoading).assign(to: &$isLoading)
        webView.publisher(for: \.canGoBack).assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward).assign(to: &$canGoForward)
        webView.publisher(for: \.estimatedProgress).assign(to: &$estimatedProgress)
        
        webView.uiDelegate = self
    }
    
    private func presentOrQueue(_ viewController: UIViewController) {
        if presentedViewController != nil {
            queue.append(viewController)
        } else {
            present(viewController, animated: true)
        }
    }
    
    private func presentQueueingViewController() {
        if queue.isEmpty == false {
            let vc = queue.removeFirst()
            present(vc, animated: true)
        }
    }
}

extension WebViewController {
    
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

extension WebViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else { return nil }
        
        let newWebView = WKWebView(frame: webView.bounds, configuration: configuration)
        let vc = WebViewController(webView: newWebView)
        vc.presentationController?.delegate = self
        vc.delegate = self
        
        presentOrQueue(vc)
        
        return newWebView
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didClose?()
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", bundle: Bundle.module, comment: "OK"), style: .default) { [weak self] _ in
            completionHandler()
            self?.presentQueueingViewController()
        }
        alertController.addAction(okAction)
        
        presentOrQueue(alertController)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle: Bundle.module, comment: "Cancel"), style: .cancel) { [weak self] _ in
            completionHandler(false)
            self?.presentQueueingViewController()
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", bundle: Bundle.module, comment: "OK"), style: .default) { [weak self] _ in
            completionHandler(true)
            self?.presentQueueingViewController()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        presentOrQueue(alertController)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        alertController.addTextField() { textField in
            textField.text = defaultText
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle: Bundle.module, comment: "Cancel"), style: .cancel) { [weak self] _ in
            completionHandler(nil)
            self?.presentQueueingViewController()
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", bundle: Bundle.module, comment: "OK"), style: .default) { [weak self, weak alertController] _ in
            completionHandler(alertController?.textFields?.first?.text)
            self?.presentQueueingViewController()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        presentOrQueue(alertController)
    }
}

extension WebViewController: UIAdaptivePresentationControllerDelegate {
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        presentQueueingViewController()
    }
}

extension WebViewController: WebViewControllerDelegate {
    
    public func didClose() {
        presentQueueingViewController()
    }
}

@objc public protocol WebViewControllerDelegate {
    @objc optional func didClose()
}

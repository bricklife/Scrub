//
//  WebViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/07/23.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import WebKit
import Combine

private func makeWKWebViewConfiguration() -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    
    configuration.allowsAirPlayForMediaPlayback = false
    configuration.mediaTypesRequiringUserActionForPlayback = []
    
#if os(iOS)
    configuration.allowsInlineMediaPlayback = true
    configuration.allowsPictureInPictureMediaPlayback = false
    configuration.dataDetectorTypes = []
#endif
    
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
    
    return configuration
}

public class WebViewController: ViewController {
    
    internal let webView: WKWebView
    
    public var didClose: (() -> Void)?
    
    @Published public private(set) var url: URL? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var estimatedProgress: Double = 0.0
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    
#if canImport(UIKit)
    private var queue: [UIViewController] = []
#endif
    
    public init() {
        self.webView = WKWebView(frame: .zero, configuration: makeWKWebViewConfiguration())
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        self.webView = WKWebView(frame: .zero, configuration: makeWKWebViewConfiguration())
        
        super.init(coder: coder)
    }
    
    public init(webView: WKWebView) {
        self.webView = webView
        
        super.init(nibName: nil, bundle: nil)
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
    
#if canImport(UIKit)
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
#endif
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

#if canImport(UIKit)
extension WebViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else { return nil }
        
        let newWebView = WKWebView(frame: webView.bounds, configuration: configuration)
        let vc = WebViewController(webView: newWebView)
        vc.presentationController?.delegate = self
        vc.didClose = { [weak self] in
            self?.presentQueueingViewController()
        }
        
        presentOrQueue(vc)
        
        return newWebView
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true) { [weak self] in
            self?.didClose?()
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
#endif

#if canImport(AppKit)
extension ViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else { return nil }
        
        let newWebView = WKWebView(frame: webView.bounds, configuration: configuration)
        
        return newWebView
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        print(#function)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
        completionHandler()
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            completionHandler(true)
        } else{
            completionHandler(false)
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = prompt
        alert.informativeText = defaultText ?? ""
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        
        alert.accessoryView = textField
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "OK")
        
        let res = alert.runModal()
        if res == .alertSecondButtonReturn {
            completionHandler(textField.stringValue)
        } else {
            completionHandler(nil)
        }
    }
    
    public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        
        openPanel.begin() { (result) in
            NSLog("Selected result " + result.rawValue.description)
            if result == .OK {
                if let url = openPanel.url {
                    completionHandler([url])
                }
            } else if result == NSApplication.ModalResponse.cancel {
                completionHandler(nil)
            }
        }
    }
}
#endif

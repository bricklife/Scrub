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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension WebViewController: NSUserInterfaceValidations {
    
    @IBAction public func goBack(_ sender: Any?) {
        webView.goBack(sender)
    }
    
    @IBAction public func goForward(_ sender: Any?) {
        webView.goForward(sender)
    }
    
    @IBAction public func reload(_ sender: Any?) {
        webView.reload(sender)
    }
    
    @IBAction public func stopLoading(_ sender: Any?) {
        webView.stopLoading(sender)
    }
    
    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return webView.validateUserInterfaceItem(item)
    }
}
#endif

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
        let okAction = UIAlertAction(title: NSLocalizedString("Close", bundle: BundleLoader.bundle, comment: "Close"), style: .default) { [weak self] _ in
            completionHandler()
            self?.presentQueueingViewController()
        }
        alertController.addAction(okAction)
        
        presentOrQueue(alertController)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle: BundleLoader.bundle, comment: "Cancel"), style: .cancel) { [weak self] _ in
            completionHandler(false)
            self?.presentQueueingViewController()
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", bundle: BundleLoader.bundle, comment: "OK"), style: .default) { [weak self] _ in
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
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", bundle: BundleLoader.bundle, comment: "Cancel"), style: .cancel) { [weak self] _ in
            completionHandler(nil)
            self?.presentQueueingViewController()
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", bundle: BundleLoader.bundle, comment: "OK"), style: .default) { [weak self, weak alertController] _ in
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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension ViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else { return nil }
        
        let width = windowFeatures.width?.doubleValue ?? webView.frame.width
        let height = windowFeatures.height?.doubleValue ?? webView.frame.height
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        let newWebView = WKWebView(frame: frame, configuration: configuration)
        let vc = WebViewController(webView: newWebView)
        let window = NSWindow(contentViewController: vc)
        let windowController = NSWindowController(window: window)
        
        windowController.showWindow(self)
        
        return newWebView
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        webView.window?.close()
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let window = webView.window else {
            completionHandler()
            return
        }
        
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: NSLocalizedString("Close", bundle: BundleLoader.bundle, comment: "Close"))
        
        alert.beginSheetModal(for: window) { res in
            completionHandler()
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let window = webView.window else {
            completionHandler(false)
            return
        }
        
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: NSLocalizedString("OK", bundle: BundleLoader.bundle, comment: "OK"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", bundle: BundleLoader.bundle, comment: "Cancel"))
        
        alert.beginSheetModal(for: window) { res in
            if res == .alertFirstButtonReturn {
                completionHandler(true)
            } else{
                completionHandler(false)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let window = webView.window else {
            completionHandler(nil)
            return
        }
        
        let alert = NSAlert()
        alert.messageText = prompt
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = defaultText ?? ""
        
        alert.accessoryView = textField
        alert.addButton(withTitle: NSLocalizedString("OK", bundle: BundleLoader.bundle, comment: "OK"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", bundle: BundleLoader.bundle, comment: "Cancel"))
        
        alert.beginSheetModal(for: window) { res in
            if res == .alertFirstButtonReturn {
                completionHandler(textField.stringValue)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        guard let window = view.window else {
            completionHandler(nil)
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        openPanel.canChooseDirectories = parameters.allowsDirectories
        
        openPanel.beginSheetModal(for: window) { (result) in
            if result == .OK, let url = openPanel.url {
                completionHandler([url])
            } else {
                completionHandler(nil)
            }
        }
    }
}
#endif

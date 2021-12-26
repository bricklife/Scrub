//
//  MainViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/24.
//

import AppKit
import Combine
import ScratchWebKit
import ScratchLink

class MainViewController: NSViewController {
    
    private weak var webViewController: ScratchWebViewController?
    private weak var toolbar: MainToolbar?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.publisher(for: \.window?.toolbar).sink { [weak self] toolbar in
            if let toolbar = toolbar as? MainToolbar {
                self?.setup(toolbar: toolbar)
            }
        }.store(in: &cancellables)
        
        if let webViewController = children.first as? ScratchWebViewController {
            setup(webViewController: webViewController)
        }
        
        //let url = URL(string: "https://bricklife.com/scratch-gui/")!
        //let url = URL(string: "https://stretch3.github.io/")!
        let url = URL(string: "https://bricklife.com/webview-checker.html")!
        webViewController?.load(url: url)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        updateToolbar(url: webViewController?.url)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func setup(webViewController: ScratchWebViewController) {
        webViewController.delegate = self
        
        webViewController.$url.sink { [weak self] url in
            self?.updateToolbar(url: url)
        }.store(in: &cancellables)
        
        webViewController.$canGoBack.sink{ [weak self] value in
            self?.toolbar?.backButton.validate()
        }.store(in: &cancellables)
        
        webViewController.$canGoForward.sink{ [weak self] value in
            self?.toolbar?.forwardButton.validate()
        }.store(in: &cancellables)
        
        webViewController.$isLoading.sink{ [weak self] value in
            self?.toolbar?.isLoading = value
        }.store(in: &cancellables)
        
        self.webViewController = children.first as? ScratchWebViewController
    }
    
    private func setup(toolbar: MainToolbar) {
        toolbar.textField.target = self
        
        toolbar.backButton.action = #selector(WebViewController.goBack(_:))
        toolbar.backButton.target = webViewController
        
        toolbar.forwardButton.action = #selector(WebViewController.goForward(_:))
        toolbar.forwardButton.target = webViewController
        
        toolbar.reloadButton.action = #selector(WebViewController.reload(_:))
        toolbar.reloadButton.target = webViewController
        
        toolbar.stopButton.action = #selector(WebViewController.stopLoading(_:))
        toolbar.stopButton.target = webViewController
        
        self.toolbar = toolbar
    }
    
    private func updateToolbar(url: URL?) {
        toolbar?.textField.stringValue = url?.absoluteString ?? ""
    }
    
    @IBAction func urlEntered(_ sender: NSTextField) {
        print(#function, sender)
        if let url = URL(string: sender.stringValue) {
            webViewController?.load(url: url)
        }
    }
}

extension MainViewController: ScratchWebViewControllerDelegate {
    func decidePolicyFor(url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void) {
        print(#function, url, isScratchEditor)
        decisionHandler(.allow)
    }
    
    func didDownloadFile(at url: URL) {
        print(#function, url)
        guard let window = view.window else { return }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = url.lastPathComponent
        
        savePanel.beginSheetModal(for: window) { res in
            if res == .OK, let newUrl = savePanel.url {
                if FileManager.default.fileExists(atPath: newUrl.path) {
                    try? FileManager.default.removeItem(atPath: newUrl.path)
                }
                try? FileManager.default.moveItem(at: url, to: newUrl)
            }
        }
    }
    
    func didFail(error: Error) {
        print(#function, error)
    }
    
    func canStartScratchLinkSession(type: SessionType) -> Bool {
        print(#function, type)
        return true
    }
    
    func didStartScratchLinkSession(type: SessionType) {
        print(#function, type)
    }
    
    func didFailStartingScratchLinkSession(type: SessionType, error: SessionError) {
        print(#function, type, error)
    }
}

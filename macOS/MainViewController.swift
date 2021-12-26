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
    private weak var windowController: MainWindowController?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.publisher(for: \.window?.windowController).sink { [weak self] windowController in
            if let windowController = windowController as? MainWindowController {
                self?.setup(windowController: windowController)
            }
        }.store(in: &cancellables)
        
        self.webViewController = children.first as? ScratchWebViewController
        webViewController?.delegate = self
        
        webViewController?.$url.sink { [weak self] url in
            self?.updateToolbar(url: url)
        }.store(in: &cancellables)
        
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
    
    private func setup(windowController: MainWindowController) {
        windowController.textField.target = self
        
        windowController.backButton.action = #selector(WebViewController.goBack)
        windowController.backButton.target = webViewController
        
        windowController.forwardButton.action = #selector(WebViewController.goForward)
        windowController.forwardButton.target = webViewController
        
        self.windowController = windowController
    }
    
    private func updateToolbar(url: URL?) {
        windowController?.textField.stringValue = url?.absoluteString ?? ""
        windowController?.backButton.validate()
        windowController?.forwardButton.validate()
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
        windowController?.backButton.validate()
        windowController?.forwardButton.validate()
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

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
    private weak var textField: NSTextField?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webViewController = children.first as? ScratchWebViewController
        webViewController?.delegate = self
        
        webViewController?.$url.sink { [weak self] url in
            self?.updateTextField(url: url)
        }.store(in: &cancellables)
        
        //let url = URL(string: "https://bricklife.com/scratch-gui/")!
        //let url = URL(string: "https://stretch3.github.io/")!
        let url = URL(string: "https://bricklife.com/webview-checker.html")!
        webViewController?.load(url: url)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.textField = view.window?.toolbar?.items.compactMap({ item in
            return item.view as? NSTextField
        }).first
        updateTextField(url: webViewController?.url)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func updateTextField(url: URL?) {
        textField?.stringValue = url?.absoluteString ?? ""
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

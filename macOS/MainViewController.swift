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
    
    private let viewModel = WebViewModel(preferences: AppDelegate.shared.preferences)
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var toolbar: MainToolbar? {
        view.window?.toolbar as? MainToolbar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let webViewController = children.first as? ScratchWebViewController {
            setup(webViewController: webViewController)
        }
        
        viewModel.inputs.sink { [weak self] input in
            switch input {
            case .goHome:
                if let url = self?.viewModel.home {
                    self?.webViewController?.load(url: url)
                } else {
                    // TODO: Alert
                }
            case .goBack:
                self?.webViewController?.goBack()
            case .goForward:
                self?.webViewController?.goForward()
            case .load(url: let url):
                self?.webViewController?.load(url: url)
            case .reload:
                self?.webViewController?.reload()
            case .stopLoading:
                self?.webViewController?.stopLoading()
            }
        }.store(in: &cancellables)
        
        viewModel.apply(inputs: .goHome)
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
        
        webViewController.$pageTitle.sink { [weak self] title in
            if let title = title {
                self?.view.window?.title = title
            }
        }.store(in: &cancellables)
        
        webViewController.$isLoading.sink{ [weak self] isLoading in
            self?.toolbar?.isLoading = isLoading
        }.store(in: &cancellables)
        
        webViewController.$canGoBack.sink{ [weak self] _ in
            self?.toolbar?.backButton.validate()
        }.store(in: &cancellables)
        
        webViewController.$canGoForward.sink{ [weak self] _ in
            self?.toolbar?.forwardButton.validate()
        }.store(in: &cancellables)
        
        self.webViewController = children.first as? ScratchWebViewController
    }
    
    private func updateToolbar(url: URL?) {
        toolbar?.textField.stringValue = url?.absoluteString ?? ""
    }
}

extension MainViewController {
    
    @objc func gotoBeginning(_ sender: Any?) {
        viewModel.apply(inputs: .goHome)
    }
    
    @objc func goBack(_ sender: Any?) {
        viewModel.apply(inputs: .goBack)
    }
    
    @objc func goForward(_ sender: Any?) {
        viewModel.apply(inputs: .goForward)
    }
    
    @objc func reload(_ sender: Any?) {
        viewModel.apply(inputs: .reload)
    }
    
    @objc func stopLoading(_ sender: Any?) {
        viewModel.apply(inputs: .stopLoading)
    }
    
    @objc func go(_ sender: Any?) {
        let urlString = toolbar?.textField.stringValue
        if let url = urlString.flatMap({ URL(string: $0) }) {
            viewModel.apply(inputs: .load(url: url))
        }
    }
}

extension MainViewController: NSUserInterfaceValidations {
    
    public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return webViewController?.validateUserInterfaceItem(item) ?? true
    }
}

extension MainViewController: ScratchWebViewControllerDelegate {
    
    func decidePolicyFor(url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void) {
        if viewModel.canAccess(url: url) || isScratchEditor {
            decisionHandler(.allow)
        } else {
            decisionHandler(.deny)
        }
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

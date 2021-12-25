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
    
    @IBOutlet weak var webViewController: ScratchWebViewController?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webViewController = children.first as? ScratchWebViewController
        webViewController?.delegate = self
        
        webViewController?.$url.sink { url in
            print(url ?? "nil")
        }.store(in: &cancellables)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //let url = URL(string: "https://bricklife.com/scratch-gui/")!
        let url = URL(string: "https://stretch3.github.io/")!
        webViewController?.load(url: url)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
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

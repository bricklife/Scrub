//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private let sessinManager = SessionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessinManager.delegate = self
        
        let js = loadJS(filename: "inject-scratch-link")
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "rpc")
        webView.configuration.userContentController.add(self, name: "download")
        
        webView.navigationDelegate = self
        
        let url = URL(string: "https://scratch.mit.edu/projects/editor/")!
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func loadJS(filename: String) -> String {
        guard let filepath = Bundle.main.path(forResource: filename, ofType: "js") else { return "" }
        return (try? String(contentsOfFile: filepath)) ?? ""
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("Requested", navigationAction.request)
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.scheme == "blob" {
            webView.evaluateJavaScript(loadJS(filename: "download"));
            decisionHandler(.cancel)
            return
        }
        
        sessinManager.closeAllSessions()
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        
        let isEditor = url.absoluteString.hasPrefix("https://scratch.mit.edu/projects/")
        if isEditor {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
        }
    }
    
}

struct Download: Codable {
    let filename: String
    let dataUri: URL
}

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let jsonString = message.body as? String else { return }
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        switch message.name {
        case "rpc":
            sessinManager.handleRequest(data: jsonData)
            
        case "download":
            guard let download = try? JSONDecoder().decode(Download.self, from: jsonData) else { break }
            guard let data = try? Data(contentsOf: download.dataUri) else { break }
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(download.filename)
            guard FileManager.default.createFile(atPath: url.path, contents: data) else { break }
            print("Saved \(data.count) bytes at", url.path)
            
            let vc: UIDocumentPickerViewController
            if #available(iOS 14.0, *) {
                vc = UIDocumentPickerViewController(forExporting: [url])
            } else {
                vc = UIDocumentPickerViewController(url: url, in: .exportToService)
            }
            vc.shouldShowFileExtensions = true
            present(vc, animated: true)
            
        default:
            break;
        }
    }
}

extension ViewController: SessionManagerDelegate {
    func recieveMessage(_ message: String, socketId: Int) {
        let js = "ScratchLink.sockets.get(\(socketId)).handleMessage('" + message + "')"
        webView.evaluateJavaScript(js)
    }
}

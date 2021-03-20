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
    
    private var sessions = [Int: BLESession]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let js = loadInjectCode()
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "rpc")
        
        webView.navigationDelegate = self
        
        let url = URL(string: "https://scratch.mit.edu/projects/editor/")!
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func loadInjectCode() -> String {
        guard let filepath = Bundle.main.path(forResource: "inject-scratch-link", ofType: "js") else { return "" }
        return (try? String(contentsOfFile: filepath)) ?? ""
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("loading", navigationAction.request)
        
        if let urlString = navigationAction.request.url?.absoluteString {
            let isEditor = urlString.hasPrefix("https://scratch.mit.edu/projects/editor/")
            webView.scrollView.isScrollEnabled = !isEditor
        }
        
        sessions.values.forEach { (session) in
            session.sessionWasClosed()
        }
        sessions.removeAll()
        
        decisionHandler(.allow)
    }
}

struct RPC: Codable {
    let method: Method
    let socketId: Int
    let url: String?
    let jsonrpc: String?
    
    enum Method: String, Codable {
        case open
        case close
        case send
    }
}

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let jsonString = message.body as? String else { return }
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        guard let rpc = try? JSONDecoder().decode(RPC.self, from: jsonData) else { return }
        
        let socketId = rpc.socketId
        
        switch rpc.method {
        case .open:
            let webSocket = WebSocket() { [weak self] (message) in
                self?.sendJsonMessage(socketId: socketId, message: message)
            }
            sessions[socketId] = try? BLESession(withSocket: webSocket)
            
        case .close:
            let session = sessions.removeValue(forKey: socketId)
            session?.sessionWasClosed()
            
        case .send:
            guard let jsonrpc = rpc.jsonrpc else { break }
            sessions[socketId]?.didReceiveText(jsonrpc)
        }
    }
    
    private func sendJsonMessage(socketId: Int, message: String) {
        let js = "ScratchLink.sockets.get(\(socketId)).handleMessage('" + message + "')"
        webView.evaluateJavaScript(js)
    }
}

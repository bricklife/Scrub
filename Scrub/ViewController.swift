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
        print("loading", navigationAction.request)
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.scheme == "blob" {
            webView.evaluateJavaScript(loadJS(filename: "download"));
            decisionHandler(.cancel)
            return
        }
        
        let isEditor = url.absoluteString.hasPrefix("https://scratch.mit.edu/projects/editor/")
        webView.scrollView.isScrollEnabled = !isEditor
        
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

struct Download: Codable {
    let filename: String
    let filetype: String
    let data: String
}

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let jsonString = message.body as? String else { return }
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        switch message.name {
        case "rpc":
            guard let rpc = try? JSONDecoder().decode(RPC.self, from: jsonData) else { break }
            
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
            
        case "download":
            guard let download = try? JSONDecoder().decode(Download.self, from: jsonData) else { break }
            guard let data = Data(base64Encoded: download.data) else { break }
            
            guard let docs = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { break }
            let path = docs.appendingPathComponent(download.filename)
            FileManager.default.createFile(atPath: path.path, contents: data, attributes: nil)
            print("Saved \(data.count) bytes at", path)
            
        default:
            break;
        }
    }
    
    private func sendJsonMessage(socketId: Int, message: String) {
        let js = "ScratchLink.sockets.get(\(socketId)).handleMessage('" + message + "')"
        webView.evaluateJavaScript(js)
    }
}

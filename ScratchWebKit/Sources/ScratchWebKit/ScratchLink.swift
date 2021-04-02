//
//  ScratchLink.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation
import WebKit

typealias uint8 = UInt8
typealias uint16 = UInt16
typealias uint32 = UInt32

enum SerializationError: Error {
    case invalid(String)
    case internalError(String)
}

public class ScratchLink: NSObject {
    
    private struct Message: Codable {
        let method: Method
        let socketId: Int
        let url: URL?
        let jsonrpc: String?
        
        enum Method: String, Codable {
            case open
            case close
            case send
        }
    }
    
    private weak var webView: WKWebView?
    
    private var sessions = [Int: Session]()
    
    private let sessionQueue = DispatchQueue.global(qos: .userInitiated)
    
    public func setup(webView: WKWebView) {
        let js = JavaScriptLoader.load(filename: "inject-scratch-link")
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "scratchLink")
        self.webView = webView
    }
    
    public func closeAllSessions() {
        sessions.values.forEach { (session) in
            session.sessionWasClosed()
        }
        sessions.removeAll()
    }
}

extension ScratchLink: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let jsonString = message.body as? String else { return }
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        guard let message = try? JSONDecoder().decode(Message.self, from: jsonData) else { return }
        
        let socketId = message.socketId
        
        switch message.method {
        case .open:
            guard let url = message.url else { break }
            let webSocket = WebSocket() { [weak self] (message) in
                DispatchQueue.main.async {
                    let js = "ScratchLink.sockets.get(\(socketId)).handleMessage('" + message + "')"
                    self?.webView?.evaluateJavaScript(js)
                }
            }
            switch url.lastPathComponent {
            case "ble":
                sessions[socketId] = try? BLESession(withSocket: webSocket)
            case "bt":
                sessions[socketId] = try? BTSession(withSocket: webSocket)
            default:
                break
            }
            
        case .close:
            let session = sessions.removeValue(forKey: socketId)
            sessionQueue.async {
                session?.sessionWasClosed()
            }
            
        case .send:
            guard let jsonrpc = message.jsonrpc else { break }
            guard let session = sessions[socketId] else { break }
            sessionQueue.async {
                session.didReceiveText(jsonrpc)
            }
        }
    }
}

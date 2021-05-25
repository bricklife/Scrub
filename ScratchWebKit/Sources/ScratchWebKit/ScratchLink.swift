//
//  ScratchLink.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation
import WebKit
import CoreBluetooth

typealias uint8 = UInt8
typealias uint16 = UInt16
typealias uint32 = UInt32

enum SerializationError: Error {
    case invalid(String)
    case internalError(String)
}

enum SessionError: Error {
    case bluetoothIsNotAvailable
}

extension SessionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .bluetoothIsNotAvailable:
            return NSLocalizedString("Bluetooth is not available", bundle: Bundle.module, comment: "Bluetooth is not available")
        }
    }
}

@objc public enum SessionType: Int {
    case ble
    case bt
    
    init?(url: URL) {
        switch url.lastPathComponent {
        case "ble":
            self = .ble
        case "bt":
            self = .bt
        default:
            return nil
        }
    }
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
    
    public weak var delegate: ScratchLinkDelegate?
    
    private weak var webView: WKWebView?
    
    private var sessions = [Int: Session]()
    
    private let sessionQueue = DispatchQueue.global(qos: .userInitiated)
    
    private let bluetoothConnectionChecker: CBCentralManager
    
    public override init() {
        self.bluetoothConnectionChecker = CBCentralManager()
        super.init()
    }
    
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
            guard let type = SessionType(url: url) else { break }
            
            guard bluetoothConnectionChecker.state == .poweredOn else {
                delegate?.didFailStartingSession(type: type, error: SessionError.bluetoothIsNotAvailable)
                break
            }
            
            let webSocket = WebSocket() { [weak self] (message) in
                DispatchQueue.main.async {
                    let js = "ScratchLink.sockets.get(\(socketId)).handleMessage('" + message + "')"
                    self?.webView?.evaluateJavaScript(js)
                }
            }
            switch type {
            case .ble:
                sessions[socketId] = try? BLESession(withSocket: webSocket)
            case .bt:
                sessions[socketId] = try? BTSession(withSocket: webSocket)
            }
            
            delegate?.didStartSession(type: type)
            
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

@objc public protocol ScratchLinkDelegate {
    @objc func didStartSession(type: SessionType)
    @objc func didFailStartingSession(type: SessionType, error: Error)
}

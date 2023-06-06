//
//  ScratchLink.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation
import WebKit
import CoreBluetooth
import Combine

typealias uint8 = UInt8
typealias uint16 = UInt16
typealias uint32 = UInt32

enum SerializationError: Error {
    case invalid(String)
    case internalError(String)
}

public enum SessionError: Error {
    case unavailable
    case bluetoothIsPoweredOff
    case bluetoothIsUnauthorized
    case bluetoothIsUnsupported
    case other(error: Error)
}

extension SessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return NSLocalizedString("This session is unavailable", bundle: Bundle.module, comment: "This session is unavailable")
        case .bluetoothIsPoweredOff:
            return NSLocalizedString("Bluetooth is powered off", bundle: Bundle.module, comment: "Bluetooth is powered off")
        case .bluetoothIsUnauthorized:
            return NSLocalizedString("Bluetooth is unauthorized", bundle: Bundle.module, comment: "Bluetooth is unauthorized")
        case .bluetoothIsUnsupported:
            return NSLocalizedString("Bluetooth is unsupported", bundle: Bundle.module, comment: "Bluetooth is unsupported")
        case .other(error: let error):
            return error.localizedDescription
        }
    }
}

public enum SessionType: String, Codable {
    case ble    = "BLE"
    case bt     = "BT"
}

public class ScratchLink: NSObject {
    
    private struct Message: Codable {
        let method: Method
        let socketId: Int
        let type: SessionType?
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
    
    private lazy var bluetoothConnectionChecker = CBCentralManager()
    private var cancellables: Set<AnyCancellable> = []
    
    public func setup(webView: WKWebView) {
        let js = JavaScriptLoader.load(filename: "inject")
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
            guard let type = message.type else { break }
            
            if let canStart = delegate?.canStartSession(type: type), canStart == false {
                delegate?.didFailStartingSession(type: type, error: .unavailable)
                break
            }
            
            bluetoothConnectionChecker.publisher(for: \.state).first(where: { $0 != .unknown }).sink { [weak self] state in
                switch state {
                case .poweredOn:
                    do {
                        try self?.open(socketId: socketId, type: type)
                        self?.delegate?.didStartSession(type: type)
                    } catch {
                        self?.delegate?.didFailStartingSession(type: type, error: .other(error: error))
                    }
                case .poweredOff:
                    self?.delegate?.didFailStartingSession(type: type, error: .bluetoothIsPoweredOff)
                case .unauthorized:
                    self?.delegate?.didFailStartingSession(type: type, error: .bluetoothIsUnauthorized)
                case .unsupported:
                    self?.delegate?.didFailStartingSession(type: type, error: .bluetoothIsUnsupported)
                default:
                    break
                }
            }.store(in: &cancellables)
            
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
    
    private func open(socketId: Int, type: SessionType) throws {
        let webSocket = WebSocket() { [weak self] (message) in
            DispatchQueue.main.async {
                let js = "ScratchLinkKit.coordinator.handleMessage(\(socketId), '\(message)')"
                self?.webView?.evaluateJavaScript(js)
            }
        }
        
        switch type {
        case .ble:
            sessions[socketId] = try BLESession(withSocket: webSocket)
        case .bt:
            sessions[socketId] = try BTSession(withSocket: webSocket)
        }
    }
}

public protocol ScratchLinkDelegate: AnyObject {
    func canStartSession(type: SessionType) -> Bool
    func didStartSession(type: SessionType)
    func didFailStartingSession(type: SessionType, error: SessionError)
}

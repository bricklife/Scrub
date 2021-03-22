//
//  SessionManager.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/22.
//

import Foundation

private struct RPC: Codable {
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

class SessionManager {
    
    weak var delegate: SessionManagerDelegate?
    
    private var sessions = [Int: Session]()
    
    private let sessionQueue = DispatchQueue(label: "com.bricklife.scrub.SessionManager")
    
    func handleRequest(data: Data) {
        guard let rpc = try? JSONDecoder().decode(RPC.self, from: data) else { return }
        
        let socketId = rpc.socketId
        
        switch rpc.method {
        case .open:
            guard let url = rpc.url else { break }
            let webSocket = WebSocket() { [weak self] (message) in
                DispatchQueue.main.async {
                    self?.delegate?.recieveMessage(message, socketId: socketId)
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
            guard let jsonrpc = rpc.jsonrpc else { break }
            guard let session = sessions[socketId] else { break }
            sessionQueue.async {
                session.didReceiveText(jsonrpc)
            }
        }
    }
    
    func closeAllSessions() {
        sessions.values.forEach { (session) in
            session.sessionWasClosed()
        }
        sessions.removeAll()
    }
}

@objc protocol SessionManagerDelegate {
    func recieveMessage(_ recieveMessage: String, socketId: Int)
}

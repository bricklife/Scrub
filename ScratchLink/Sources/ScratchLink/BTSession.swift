//
//  BTSession.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/21.
//

import Foundation
import ExternalAccessory

class BTSession: Session {
    private var connectedSession: EASession?
    private var state: SessionState = .initial
    private var ouiPrefix: String
    
    private let streamDelegateHelper: StreamDelegateHelper
    
    private var messageQueue: [(Data, JSONRPCCompletionHandler)] = []
    
    private var didRegisterForLocalNotifications = false
    
    private enum SessionState {
        case initial
        case discovery
        case connected
    }
    
    required init(withSocket webSocket: WebSocket) throws {
        self.streamDelegateHelper = StreamDelegateHelper()
        self.ouiPrefix = ""
        try super.init(withSocket: webSocket)
        self.streamDelegateHelper.delegate = self
    }
    
    deinit {
        if didRegisterForLocalNotifications {
            EAAccessoryManager.shared().unregisterForLocalNotifications()
        }
    }
    
    override func didReceiveCall(_ method: String, withParams params: [String: Any], completion: @escaping JSONRPCCompletionHandler) throws {
        switch state {
        case .initial:
            if method == "discover" {
                if let major = params["majorDeviceClass"] as? UInt, let minor = params["minorDeviceClass"] as? UInt {
                    if let prefix = params["ouiPrefix"] as? String { self.ouiPrefix = prefix }
                    state = .discovery
                    discover(inMajorDeviceClass: major, inMinorDeviceClass: minor, completion: completion)
                } else {
                    completion(nil, JSONRPCError.invalidParams(data: "majorDeviceClass and minorDeviceClass required"))
                }
                return
            }
        case .discovery:
            if method == "connect" {
                if let peripheralId = params["peripheralId"] as? Int {
                    connect(toDevice: peripheralId, completion: completion)
                } else {
                    completion(nil, JSONRPCError.invalidParams(data: "peripheralId required"))
                }
                return
            }
        case .connected:
            if method == "send" {
                let decodedMessage = try EncodingHelpers.decodeBuffer(fromJSON: params)
                sendMessage(decodedMessage, completion: completion)
                return
            }
        }
        // unrecognized method in this state: pass to base class
        try super.didReceiveCall(method, withParams: params, completion: completion)
    }
    
    override func sessionWasClosed() {
        connectedSession?.inputStream?.close()
        connectedSession?.inputStream?.remove(from: .main, forMode: .default)
        connectedSession?.inputStream?.delegate = nil
        
        connectedSession?.outputStream?.close()
        connectedSession?.outputStream?.remove(from: .main, forMode: .default)
        connectedSession?.outputStream?.delegate = nil
        
        connectedSession = nil
        
        super.sessionWasClosed()
    }
    
    private func discover(inMajorDeviceClass major: UInt, inMinorDeviceClass minor: UInt, completion: @escaping JSONRPCCompletionHandler) {
        sendDiscoveredPeripherals()
        
        if !didRegisterForLocalNotifications {
            didRegisterForLocalNotifications = true
            EAAccessoryManager.shared().registerForLocalNotifications()
            NotificationCenter.default.addObserver(forName: .EAAccessoryDidConnect, object: nil, queue: .main) { [weak self] _ in
                self?.sendDiscoveredPeripherals()
            }
        }
        
        completion(nil, nil)
    }
    
    private func sendDiscoveredPeripherals() {
        let connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        
        for accessory in connectedAccessories {
            let name: String
            if accessory.protocolStrings.contains("COM.LEGO.MINDSTORMS.EV3") {
                name = "LEGO MINDSTORMS EV3"
            } else {
                name = accessory.name
            }
            
            let peripheralData: [String: Any] = [
                "peripheralId": accessory.connectionID,
                "name": name,
                "rssi": RSSI.unsupported.rawValue ?? 0
            ]
            DispatchQueue.main.async {
                self.sendRemoteRequest("didDiscoverPeripheral", withParams: peripheralData)
            }
        }
    }
    
    private func connect(toDevice deviceId: Int, completion: @escaping JSONRPCCompletionHandler) {
        let connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        
        guard let accessory = connectedAccessories.first(where: {$0.connectionID == deviceId}),
              let protocolString = accessory.protocolStrings.first,
              let session = EASession(accessory: accessory, forProtocol: protocolString) else {
            completion(nil, JSONRPCError.invalidRequest(data: "Device \(deviceId) not available for connection"))
            return
        }
        
        self.connectedSession = session
        
        session.inputStream?.delegate = self.streamDelegateHelper
        session.inputStream?.schedule(in: .main, forMode: .default)
        session.inputStream?.open()
        
        session.outputStream?.delegate = self.streamDelegateHelper
        session.outputStream?.schedule(in: .main, forMode: .default)
        session.outputStream?.open()
        
        self.state = .connected
        completion(nil, nil)
    }
    
    private func sendMessage(_ message: Data, completion: @escaping JSONRPCCompletionHandler) {
        guard let outputStream = connectedSession?.outputStream else {
            completion(nil, JSONRPCError.serverError(code: -32500, data: "No peripheral connected"))
            return
        }
        
        guard outputStream.hasSpaceAvailable else {
            messageQueue.append((message, completion))
            return
        }
        
        message.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
            if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                let count = outputStream.write(bytes, maxLength: buffer.count)
                if count > 0 {
                    completion(count, nil)
                } else {
                    completion(nil, JSONRPCError.serverError(code: -32500, data: "Failed to send message"))
                }
            } else {
                completion(nil, JSONRPCError.serverError(code: -32500, data: "Failed to send message"))
            }
        }
    }
}

extension BTSession: SwiftStreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            break
            
        case .hasSpaceAvailable:
            if !messageQueue.isEmpty {
                let message = messageQueue.removeFirst()
                sendMessage(message.0, completion: message.1)
            }
            
        case .hasBytesAvailable:
            guard let data = readFromStream() else { break }
            guard let responseData = EncodingHelpers.encodeBuffer(data, withEncoding: "base64") else { break }
            sendRemoteRequest("didReceiveMessage", withParams: responseData)
            
        case .endEncountered:
            break
            
        case .errorOccurred:
            sessionWasClosed()
            
        default:
            break
        }
    }
    
    private func readFromStream() -> Data? {
        guard let inputStream = connectedSession?.inputStream else { return nil }
        
        var readBuffer = [UInt8]()
        let bufferSize = 128
        var buf = [UInt8](repeating: 0x00, count: bufferSize)
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buf, maxLength: bufferSize)
            if bytesRead == -1 {
                return nil
            } else if bytesRead == 0 {
                break
            }
            readBuffer.append(contentsOf: buf.prefix(bytesRead))
        }
        
        return Data(readBuffer)
    }
}

private class StreamDelegateHelper: NSObject, StreamDelegate {
    weak var delegate: SwiftStreamDelegate?
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        delegate?.stream(aStream, handle: eventCode)
    }
}

private protocol SwiftStreamDelegate: AnyObject {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
}

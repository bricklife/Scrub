#if os(iOS) || os(visionOS)
import UIKit
import WebKit
import WebBluetoothCore

public enum WebBluetoothError: Error {
    case bluetoothIsPoweredOff
    case bluetoothIsUnauthorized
    case bluetoothIsUnsupported
}

extension WebBluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bluetoothIsPoweredOff:
            return NSLocalizedString("Bluetooth is powered off", bundle: .module, comment: "")
        case .bluetoothIsUnauthorized:
            return NSLocalizedString("Bluetooth is unauthorized", bundle: .module, comment: "")
        case .bluetoothIsUnsupported:
            return NSLocalizedString("Bluetooth is unsupported", bundle: .module, comment: "")
        }
    }
}

public protocol WebBluetoothDelegate: AnyObject {
    func webBluetooth(_ webBluetooth: WebBluetooth, didFail error: WebBluetoothError)
}

public class WebBluetooth: NSObject {
    
    public weak var delegate: WebBluetoothDelegate?
    
    private let central = BluetoothCentral()
    private weak var webView: WKWebView?
    
    public func setup(webView: WKWebView) {
        let js = WebBluetoothJavaScript.injectSource
        guard !js.isEmpty else { return }
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "webBluetooth")
        self.webView = webView
        
        central.onDisconnect = { [weak self] deviceId in
            self?.send(["method": "gattserverdisconnected", "deviceId": deviceId])
        }
        central.onValueChanged = { [weak self] characteristicId, value in
            self?.send([
                "method": "characteristicvaluechanged",
                "characteristicId": characteristicId,
                "value": value
            ])
        }
        central.onAvailabilityChanged = { [weak self] available in
            self?.send(["method": "availabilitychanged", "available": available])
        }
        central.onBluetoothFailed = { [weak self] error in
            guard let self = self else { return }
            self.delegate?.webBluetooth(self, didFail: error)
        }
    }
    
    public func reset() {
        central.reset()
    }
    
    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript("WebBluetoothKit.coordinator.handleNativeMessage(\(json))", completionHandler: nil)
        }
    }
    
    private func respond(requestId: Int, result: Any = NSNull(), error: DOMError? = nil) {
        var payload: [String: Any] = [
            "method": "response",
            "requestId": requestId,
            "result": result
        ]
        if let error = error {
            payload["error"] = error.dictionary
        }
        send(payload)
    }
    
    private func presenter() -> UIViewController? {
        var responder: UIResponder? = webView
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}

extension WebBluetooth: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String,
              let requestId = Self.intValue(body["requestId"]) else { return }
        
        switch method {
        case "getAvailability":
            central.getAvailability { [weak self] available in
                self?.respond(requestId: requestId, result: available)
            }
            
        case "requestDevice":
            guard let presenter = presenter() else {
                respond(requestId: requestId, error: .invalidState("Cannot present a device chooser"))
                return
            }
            do {
                let options = try RequestDeviceOptions.parse(body["options"])
                central.requestDevice(options: options, presenter: presenter) { [weak self] result in
                    switch result {
                    case .success(let device):
                        self?.respond(requestId: requestId, result: device.dictionary)
                    case .failure(let error):
                        self?.respond(requestId: requestId, error: error)
                    }
                }
            } catch let error as DOMError {
                respond(requestId: requestId, error: error)
            } catch {
                respond(requestId: requestId, error: .typeError(error.localizedDescription))
            }
            
        case "gattConnect":
            guard let deviceId = body["deviceId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing deviceId"))
                return
            }
            central.connect(deviceId: deviceId) { [weak self] result in
                switch result {
                case .success:
                    self?.respond(requestId: requestId)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        case "gattDisconnect":
            if let deviceId = body["deviceId"] as? String {
                central.disconnect(deviceId: deviceId)
            }
            respond(requestId: requestId)
            
        case "getPrimaryServices":
            guard let deviceId = body["deviceId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing deviceId"))
                return
            }
            central.getPrimaryServices(deviceId: deviceId, service: body["service"]) { [weak self] result in
                switch result {
                case .success(let services):
                    self?.respond(requestId: requestId, result: services)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        case "getCharacteristics":
            guard let serviceId = body["serviceId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing serviceId"))
                return
            }
            central.getCharacteristics(serviceId: serviceId, characteristic: body["characteristic"]) { [weak self] result in
                switch result {
                case .success(let characteristics):
                    self?.respond(requestId: requestId, result: characteristics)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        case "readValue":
            guard let characteristicId = body["characteristicId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing characteristicId"))
                return
            }
            central.readValue(characteristicId: characteristicId) { [weak self] result in
                switch result {
                case .success(let value):
                    self?.respond(requestId: requestId, result: value)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        case "writeValue":
            guard let characteristicId = body["characteristicId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing characteristicId"))
                return
            }
            let bytes = Self.byteArray(body["data"]) ?? []
            let withResponse = body["withResponse"] as? Bool
            central.writeValue(characteristicId: characteristicId, bytes: bytes, withResponse: withResponse) { [weak self] result in
                switch result {
                case .success:
                    self?.respond(requestId: requestId)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        case "setNotify":
            guard let characteristicId = body["characteristicId"] as? String else {
                respond(requestId: requestId, error: .typeError("Missing characteristicId"))
                return
            }
            let enabled = body["enabled"] as? Bool ?? false
            central.setNotify(characteristicId: characteristicId, enabled: enabled) { [weak self] result in
                switch result {
                case .success:
                    self?.respond(requestId: requestId)
                case .failure(let error):
                    self?.respond(requestId: requestId, error: error)
                }
            }
            
        default:
            respond(requestId: requestId, error: .notSupported("Unknown method \(method)"))
        }
    }
    
    private static func byteArray(_ value: Any?) -> [UInt8]? {
        if let value = value as? [UInt8] { return value }
        if let value = value as? [Int] { return value.map { UInt8(truncatingIfNeeded: $0) } }
        if let value = value as? [NSNumber] { return value.map { $0.uint8Value } }
        return nil
    }
    
    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }
}
#endif

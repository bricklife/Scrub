import WebKit

enum MessageName: String {
    case requestMIDIAccess
    case connectMIDIInput
    case sendMIDIMessage
    case clearMIDIOutput
}

public class WebMIDI: NSObject {
    
    private let midiClient = MIDIClient()
    
    private weak var webView: WKWebView?
    
    public func setup(webView: WKWebView) {
        guard let filepath = Bundle.module.path(forResource: "web-midi-api", ofType: "js") else { return }
        guard let js = try? String(contentsOfFile: filepath) else { return }
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        
        webView.configuration.userContentController.add(self, name: MessageName.requestMIDIAccess.rawValue)
        webView.configuration.userContentController.add(self, name: MessageName.connectMIDIInput.rawValue)
        webView.configuration.userContentController.add(self, name: MessageName.sendMIDIMessage.rawValue)
        webView.configuration.userContentController.add(self, name: MessageName.clearMIDIOutput.rawValue)
        self.webView = webView
        
        try? midiClient.setup()
        
        midiClient.portAddedHander = { [weak self] (port) in
            DispatchQueue.main.async {
                self?.webView?.evaluateJavaScript("WebMIDI.shared.receiveMIDIConnection(\(port.jsString))")
            }
        }
        
        midiClient.portRemovedHander = { [weak self] (port) in
            DispatchQueue.main.async {
                self?.webView?.evaluateJavaScript("WebMIDI.shared.receiveMIDIConnection(\(port.jsString))")
            }
        }
        
        midiClient.messageReceivedHander = { [weak self] (id, data) in
            DispatchQueue.main.async {
                let d = "[" + data.map({ String($0) }).joined(separator: ", ") + "]"
                self?.webView?.evaluateJavaScript("WebMIDI.shared.receiveMIDIMessage('\(id)', \(d))")
            }
        }
    }
    
    public func reset() {
        try? midiClient.reset()
    }
}

extension WebMIDI: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let name = MessageName(rawValue: message.name), let parameters = message.body as? [String : Any] else { return }
        
        switch name {
        case .requestMIDIAccess:
            guard let requestId = parameters["requestId"] as? Int else { break }
            let ports = midiClient.getMIDIPorts()
            let inputs = "[" + ports.inputs.map(\.jsString).joined(separator: ", ") + "]"
            let outputs = "[" + ports.outputs.map(\.jsString).joined(separator: ", ") + "]"
            webView?.evaluateJavaScript("WebMIDI.shared.responseMIDIAccess(\(requestId), \(inputs), \(outputs))")
            
        case .connectMIDIInput:
            guard let id = (parameters["id"] as? String).flatMap({ MIDI.UniqueID($0) }) else { break }
            try? midiClient.connectMIDIInput(id: id)
            
        case .sendMIDIMessage:
            guard let id = (parameters["id"] as? String).flatMap({ MIDI.UniqueID($0) }) else { break }
            guard let data = parameters["data"] as? [UInt8] else { break }
            try? midiClient.sendMIDIMessage(id: id, data: data)
            
        case .clearMIDIOutput:
            guard let id = (parameters["id"] as? String).flatMap({ MIDI.UniqueID($0) }) else { break }
            try? midiClient.clearMIDIOutput(id: id)
        }
    }
}

extension MIDIPort {
    
    var jsString: String {
        "{id: '\(id)', type: '\(type.rawValue)', name: \(name.jsString), manufacturer: \(manufacturer.jsString), state: '\(state.rawValue)'}"
    }
}

extension Optional where Wrapped == String {
    
    var jsString: String {
        return self.flatMap { "'\($0)'" } ?? "null"
    }
}

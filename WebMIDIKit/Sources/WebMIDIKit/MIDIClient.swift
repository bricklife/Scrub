import MIDI

class MIDIClient {
    
    private var client: MIDI.Client?
    private var inputPort: MIDI.InputPort?
    private var outputPort: MIDI.OutputPort?
    
    private var ports: [MIDI.Endpoint.Ref : MIDIPort] = [:]
    private var connectedPortIds: [MIDI.UniqueID] = []
    
    var messageReceivedHander: ((MIDI.UniqueID, [UInt8], MIDI.TimeStamp?) -> Void)?
    var portAddedHander: ((MIDIPort) -> Void)?
    var portRemovedHander: ((MIDIPort) -> Void)?
    
    func setup() throws {
        self.client = try MIDI.Client(name: "WebMIDIClient") { [weak self] notification in
            switch notification {
            case .endpointAdded(let endpoint):
                if let port = self?.ports[endpoint.ref] {
                    port.state = .connected
                    self?.portAddedHander?(port)
                } else {
                    let port = MIDIPort(endpoint: endpoint, state: .connected)
                    self?.ports[endpoint.ref] = port
                    self?.portAddedHander?(port)
                }
                
            case .endpointRemoved(let endpoint):
                if let port = self?.ports[endpoint.ref] {
                    port.state = .disconnected
                    self?.portRemovedHander?(port)
                } else {
                    let port = MIDIPort(endpoint: endpoint, state: .disconnected)
                    self?.ports[endpoint.ref] = port
                    self?.portRemovedHander?(port)
                }
                
            case .other:
                break
            }
        }
        
        self.inputPort = try client?.createInputPort(name: "inputPort") { [weak self] (packetList, endpoint) in
            guard let id = self?.ports[endpoint.ref]?.id else { return }
            for packet in packetList {
                let delay = packet.timeStamp.map({ $0 - .now })
                self?.messageReceivedHander?(id, packet.data, delay)
            }
        }
        
        self.outputPort = try client?.createOutputPort(name: "outputPort")
    }
    
    func getMIDIPorts() -> (inputs: [MIDIPort], outputs: [MIDIPort]) {
        var inputs = [MIDIPort]()
        for src in MIDI.Endpoint.getSources() {
            let port = MIDIPort(endpoint: src, state: .connected)
            inputs.append(port)
            
            if ports.keys.contains(port.endpoint.ref) == false {
                ports[port.endpoint.ref] = port
            }
        }
        
        var outputs = [MIDIPort]()
        for dest in MIDI.Endpoint.getDestinations() {
            let port = MIDIPort(endpoint: dest, state: .connected)
            outputs.append(port)
            
            if ports.keys.contains(port.endpoint.ref) == false {
                ports[port.endpoint.ref] = port
            }
        }
        
        return (inputs: inputs, outputs: outputs)
    }
    
    func connectMIDIInput(id: MIDI.UniqueID) throws {
        guard let port = ports.values.first(where: { $0.id == id }) else { return }
        
        if !connectedPortIds.contains(port.id) {
            try inputPort?.connect(source: port.endpoint)
            connectedPortIds.append(port.id)
        }
    }
    
    func sendMIDIMessage(id: MIDI.UniqueID, data: [UInt8], deltaMS: Double?) throws {
        guard let port = ports.values.first(where: { $0.id == id }) else { return }
        
        let timeStamp = deltaMS.map({ MIDI.TimeStamp.now + MIDI.TimeStamp($0) })
        let packet = MIDI.Packet(data: data, timeStamp: timeStamp)
        try outputPort?.send(packet: packet, to: port.endpoint)
    }
    
    func clearMIDIOutput(id: MIDI.UniqueID) throws {
        guard let port = ports.values.first(where: { $0.id == id }) else { return }
        
        try outputPort?.flush(destination: port.endpoint)
    }
    
    func reset() throws {
        for port in ports.values {
            if connectedPortIds.contains(port.id) {
                try inputPort?.disconnect(source: port.endpoint)
            }
        }
        ports = [:]
        connectedPortIds = []
    }
}

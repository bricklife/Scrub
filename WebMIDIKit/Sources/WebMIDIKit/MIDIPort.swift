import MIDI

enum MIDIPortType: String {
    case input
    case output
}

enum MIDIPortState: String {
    case disconnected
    case connected
}

class MIDIPort {
    
    let endpoint: MIDI.Endpoint
    let type: MIDIPortType
    var state: MIDIPortState
    
    let id: MIDI.UniqueID
    let name: String?
    let manufacturer: String?
    
    init(endpoint: MIDI.Endpoint, state: MIDIPortState) {
        self.endpoint = endpoint
        self.type = endpoint.type.portType
        self.state = state
        
        self.id = endpoint.uniqueID ?? 0
        self.name = endpoint.name
        self.manufacturer = endpoint.manufacturer
    }
}

extension MIDI.EndpointType {
    
    var portType: MIDIPortType {
        switch self {
        case .source:
            return .input
        case .destination:
            return .output
        }
    }
}

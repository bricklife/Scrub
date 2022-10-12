import CoreMIDI

enum MIDI {
    typealias UniqueID = MIDIUniqueID
    
    enum Error: Swift.Error {
        case osStatus(OSStatus)
        case invalidType
    }
    
    enum Notification {
        case endpointAdded(Endpoint)
        case endpointRemoved(Endpoint)
        case other
    }
    
    struct Packet {
        typealias List = Array<Packet>
        
        let data: [UInt8]
    }
    
    class Client {
        typealias Ref = MIDIClientRef
        
        let ref: Ref
        
        init(name: String, notifyBlock: @escaping (Notification) -> Void) throws {
            var clientRef = MIDIPortRef()
            let result = MIDIClientCreateWithBlock(name as CFString, &clientRef, { notificationPtr in
                let notification = notificationPtr.pointee
                switch notification.messageID {
                case .msgObjectAdded:
                    let rawPtr = UnsafeRawPointer(notificationPtr)
                    let message = rawPtr.assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
                    if let type = EndpointType(objectType: message.childType) {
                        let endpoint = Endpoint(ref: message.child, type: type)
                        notifyBlock(.endpointAdded(endpoint))
                    }
                    
                case .msgObjectRemoved:
                    let rawPtr = UnsafeRawPointer(notificationPtr)
                    let message = rawPtr.assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
                    if let type = EndpointType(objectType: message.childType) {
                        let endpoint = Endpoint(ref: message.child, type: type)
                        notifyBlock(.endpointRemoved(endpoint))
                    }
                    
                default:
                    notifyBlock(.other)
                }
            })
            guard result == noErr else {
                throw Error.osStatus(result)
            }
            
            self.ref = clientRef
        }
        
        func createInputPort(name: String, readBlock: @escaping (Packet.List, Endpoint) -> Void) throws -> InputPort {
            var portRef = MIDIPortRef()
            let result = MIDIInputPortCreateWithBlock(ref, name as CFString, &portRef, { pktlist, srcConnRefCon in
                guard let srcConnRefCon = srcConnRefCon else { return }
                let endpoint = Unmanaged<Endpoint>.fromOpaque(srcConnRefCon).takeUnretainedValue()
                
                let list = pktlist.unsafeSequence().map { packetPtr -> Packet in
                    let data = Array(packetPtr.bytes())
                    return Packet(data: data)
                }
                
                readBlock(list, endpoint)
            })
            guard result == noErr else {
                throw Error.osStatus(result)
            }
            
            return InputPort(ref: portRef)
        }
        
        func createOutputPort(name: String) throws -> OutputPort {
            var portRef = MIDIPortRef()
            let result = MIDIOutputPortCreate(ref, name as CFString, &portRef)
            guard result == noErr else {
                throw Error.osStatus(result)
            }
            
            return OutputPort(ref: portRef)
        }
    }
    
    class Port {
        typealias Ref = MIDIPortRef
        
        let ref: Ref
        
        init(ref: Ref) {
            self.ref = ref
        }
    }
    
    class InputPort: Port {
        
        func connect(source: Endpoint) throws {
            guard source.type == .source else { throw Error.invalidType }
            
            let result = MIDIPortConnectSource(ref, source.ref, Unmanaged.passUnretained(source).toOpaque())
            guard result == noErr else {
                throw Error.osStatus(result)
            }
        }
        
        func disconnect(source: Endpoint) throws {
            guard source.type == .source else { throw Error.invalidType }
            
            let result = MIDIPortDisconnectSource(ref, source.ref)
            guard result == noErr else {
                throw Error.osStatus(result)
            }
        }
    }
    
    class OutputPort: Port {
        
        func send(packet: Packet, to destination: Endpoint) throws {
            guard destination.type == .destination else { throw Error.invalidType }
            
            let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: packet.data.count)
            for c in packet.data {
                builder.append(c)
            }
            
            let packet = builder.withUnsafePointer { pointer in
                pointer.pointee
            }
            
            var packetList = MIDIPacketList(numPackets: 1, packet: packet)
            
            let result = MIDISend(ref, destination.ref, &packetList)
            guard result == noErr else {
                throw Error.osStatus(result)
            }
        }
        
        func flush(destination: Endpoint) throws {
            guard destination.type == .destination else { throw Error.invalidType }
            
            let result = MIDIFlushOutput(destination.ref)
            guard result == noErr else {
                throw Error.osStatus(result)
            }
        }
    }
    
    enum EndpointType {
        case source
        case destination
        
        init?(objectType: MIDIObjectType) {
            switch objectType {
            case .source:
                self = .source
            case .destination:
                self = .destination
            default:
                return nil
            }
        }
    }
    
    class Endpoint {
        typealias Ref = MIDIEndpointRef
        
        let ref: Ref
        let type: EndpointType
        
        var uniqueID: UniqueID? {
            var value: MIDI.UniqueID = 0
            guard MIDIObjectGetIntegerProperty(ref, kMIDIPropertyUniqueID, &value) == noErr else { return nil }
            return value
        }
        
        var name: String? {
            var value: Unmanaged<CFString>?
            guard MIDIObjectGetStringProperty(ref, kMIDIPropertyName, &value) == noErr else { return nil }
            return value?.takeRetainedValue() as String?
        }
        
        var manufacturer: String? {
            var value: Unmanaged<CFString>?
            guard MIDIObjectGetStringProperty(ref, kMIDIPropertyManufacturer, &value) == noErr else { return nil }
            return value?.takeRetainedValue() as String?
        }
        
        init(ref: Ref, type: EndpointType) {
            self.ref = ref
            self.type = type
        }
        
        static func getSources() -> [Endpoint] {
            let numberOfSources = MIDIGetNumberOfSources()
            var sources = [Endpoint]()
            for i in 0 ..< numberOfSources {
                sources.append(Endpoint(ref: MIDIGetSource(i), type: .source))
            }
            return sources
        }
        
        static func getDestinations() -> [Endpoint] {
            let numberOfDestinationas = MIDIGetNumberOfDestinations()
            var destinations = [Endpoint]()
            for i in 0 ..< numberOfDestinationas {
                destinations.append(Endpoint(ref: MIDIGetDestination(i), type: .destination))
            }
            return destinations
        }
    }
}

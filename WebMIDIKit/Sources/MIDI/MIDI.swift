import CoreMIDI

public typealias UniqueID = MIDIUniqueID

public enum Error: Swift.Error {
    case osStatus(OSStatus)
    case invalidType
}

public enum Notification {
    case endpointAdded(Endpoint)
    case endpointRemoved(Endpoint)
    case other
}

public class Client {
    public typealias Ref = MIDIClientRef
    
    public let ref: Ref
    
    public init(name: String, notifyBlock: @escaping (Notification) -> Void) throws {
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
    
    public func createInputPort(name: String, readBlock: @escaping (Packet.List, Endpoint) -> Void) throws -> InputPort {
        var portRef = MIDIPortRef()
        let result = MIDIInputPortCreateWithBlock(ref, name as CFString, &portRef, { pktlist, srcConnRefCon in
            guard let srcConnRefCon = srcConnRefCon else { return }
            let endpoint = Unmanaged<Endpoint>.fromOpaque(srcConnRefCon).takeUnretainedValue()
            
            let list = pktlist.unsafeSequence().map { packetPtr -> Packet in
                let data = Array(packetPtr.bytes())
                return Packet(data: data, timeStamp: TimeStamp(packetPtr.pointee.timeStamp))
            }
            
            readBlock(list, endpoint)
        })
        guard result == noErr else {
            throw Error.osStatus(result)
        }
        
        return InputPort(ref: portRef)
    }
    
    public func createOutputPort(name: String) throws -> OutputPort {
        var portRef = MIDIPortRef()
        let result = MIDIOutputPortCreate(ref, name as CFString, &portRef)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
        
        return OutputPort(ref: portRef)
    }
}

public class Port {
    public typealias Ref = MIDIPortRef
    
    public let ref: Ref
    
    init(ref: Ref) {
        self.ref = ref
    }
}

public class InputPort: Port {
    
    public func connect(source: Endpoint) throws {
        guard source.type == .source else { throw Error.invalidType }
        
        let result = MIDIPortConnectSource(ref, source.ref, Unmanaged.passUnretained(source).toOpaque())
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
    
    public func disconnect(source: Endpoint) throws {
        guard source.type == .source else { throw Error.invalidType }
        
        let result = MIDIPortDisconnectSource(ref, source.ref)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
}

public class OutputPort: Port {
    
    public func send(packet: Packet, to destination: Endpoint) throws {
        guard destination.type == .destination else { throw Error.invalidType }
        
        let packet = packet.coreMidiPacket
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        
        let result = MIDISend(ref, destination.ref, &packetList)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
    
    public func flush(destination: Endpoint) throws {
        guard destination.type == .destination else { throw Error.invalidType }
        
        let result = MIDIFlushOutput(destination.ref)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
}

public enum EndpointType {
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

public class Endpoint {
    public typealias Ref = MIDIEndpointRef
    
    public let ref: Ref
    public let type: EndpointType
    
    public var uniqueID: UniqueID? {
        var value: UniqueID = 0
        guard MIDIObjectGetIntegerProperty(ref, kMIDIPropertyUniqueID, &value) == noErr else { return nil }
        return value
    }
    
    public var name: String? {
        var value: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(ref, kMIDIPropertyName, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    
    public var manufacturer: String? {
        var value: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(ref, kMIDIPropertyManufacturer, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    
    init(ref: Ref, type: EndpointType) {
        self.ref = ref
        self.type = type
    }
    
    public static func getSources() -> [Endpoint] {
        let numberOfSources = MIDIGetNumberOfSources()
        var sources = [Endpoint]()
        for i in 0 ..< numberOfSources {
            sources.append(Endpoint(ref: MIDIGetSource(i), type: .source))
        }
        return sources
    }
    
    public static func getDestinations() -> [Endpoint] {
        let numberOfDestinationas = MIDIGetNumberOfDestinations()
        var destinations = [Endpoint]()
        for i in 0 ..< numberOfDestinationas {
            destinations.append(Endpoint(ref: MIDIGetDestination(i), type: .destination))
        }
        return destinations
    }
}

public struct Packet {
    public typealias List = Array<Packet>
    
    public let data: [UInt8]
    public let timeStamp: TimeStamp?
    
    public init(data: [UInt8], timeStamp: TimeStamp? = nil) {
        self.data = data
        self.timeStamp = timeStamp
    }
    
    public var coreMidiPacket: MIDIPacket {
        let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: data.count)
        
        for byte in data {
            builder.append(byte)
        }
        
        return builder.withUnsafePointer { pointer -> MIDIPacket in
            var packet = pointer.pointee
            packet.timeStamp = timeStamp?.coreMidiTimeStamp ?? 0
            return packet
        }
    }
}

public struct TimeStamp {
    
    private static let timebase: mach_timebase_info = {
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)
        return timebase
    }()
    
    public static var now: TimeStamp {
        TimeStamp(mach_absolute_time())
    }
    
    public var milliSeconds: Double {
        Double(coreMidiTimeStamp) * Double(Self.timebase.numer) / Double(Self.timebase.denom) / 1_000_000
    }
    
    public let coreMidiTimeStamp: MIDITimeStamp
    
    public init() {
        self.coreMidiTimeStamp = 0
    }
    
    public init(_ coreMidiTimeStamp: MIDITimeStamp) {
        self.coreMidiTimeStamp = coreMidiTimeStamp
    }
    
    public init(_ milliSeconds: Double) {
        let value = milliSeconds * 1_000_000 * Double(Self.timebase.denom) / Double(Self.timebase.numer)
        if Double(MIDITimeStamp.min)...Double(MIDITimeStamp.max) ~= value {
            self.coreMidiTimeStamp = MIDITimeStamp(value)
        } else {
            self.coreMidiTimeStamp = MIDITimeStamp(0)
        }
    }
}

public func +(left: TimeStamp, right: TimeStamp) -> TimeStamp {
    let value = left.coreMidiTimeStamp &+ right.coreMidiTimeStamp
    guard value >= left.coreMidiTimeStamp else {
        return TimeStamp()
    }
    return TimeStamp(value)
}

public func -(left: TimeStamp, right: TimeStamp) -> TimeStamp {
    let value = left.coreMidiTimeStamp &- right.coreMidiTimeStamp
    guard value <= left.coreMidiTimeStamp else {
        return TimeStamp()
    }
    return TimeStamp(value)
}

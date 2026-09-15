import CoreBluetooth
import Foundation

public struct Advertisement {
    public var name: String?
    public var serviceUUIDs: Set<CBUUID>
    public var manufacturerData: Data?
    
    public init(name: String?, serviceUUIDs: Set<CBUUID>, manufacturerData: Data?) {
        self.name = name
        self.serviceUUIDs = serviceUUIDs
        self.manufacturerData = manufacturerData
    }
    
    public init(peripheral: CBPeripheral, advertisementData: [String: Any]) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.name = advertisedName ?? peripheral.name
        
        var services = Set<CBUUID>()
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            services.formUnion(uuids)
        }
        if let uuids = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] {
            services.formUnion(uuids)
        }
        if let peripheralServices = peripheral.services {
            services.formUnion(peripheralServices.map(\.uuid))
        }
        self.serviceUUIDs = services
        self.manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
}

public struct ManufacturerDataFilter {
    public let companyIdentifier: UInt16
    public let dataPrefix: [UInt8]
    public let mask: [UInt8]
    
    public init(companyIdentifier: UInt16, dataPrefix: [UInt8], mask: [UInt8]) {
        self.companyIdentifier = companyIdentifier
        self.dataPrefix = dataPrefix
        self.mask = mask
    }
}

public struct ScanFilter {
    public var name: String?
    public var namePrefix: String?
    public var services: Set<CBUUID>?
    public var manufacturerData: [ManufacturerDataFilter]?
    
    public init(
        name: String? = nil,
        namePrefix: String? = nil,
        services: Set<CBUUID>? = nil,
        manufacturerData: [ManufacturerDataFilter]? = nil
    ) {
        self.name = name
        self.namePrefix = namePrefix
        self.services = services
        self.manufacturerData = manufacturerData
    }
    
    public var isEmpty: Bool {
        let hasName = !(name?.isEmpty ?? true)
        let hasPrefix = !(namePrefix?.isEmpty ?? true)
        let hasServices = !(services?.isEmpty ?? true)
        let hasManufacturer = !(manufacturerData?.isEmpty ?? true)
        return !hasName && !hasPrefix && !hasServices && !hasManufacturer
    }
    
    public func matches(_ advertisement: Advertisement) -> Bool {
        if let name = name {
            guard let advertisedName = advertisement.name, advertisedName == name else {
                return false
            }
        }
        
        if let namePrefix = namePrefix, !namePrefix.isEmpty {
            guard let advertisedName = advertisement.name, advertisedName.hasPrefix(namePrefix) else {
                return false
            }
        }
        
        if let services = services, !services.isEmpty {
            if !services.isSubset(of: advertisement.serviceUUIDs) {
                return false
            }
        }
        
        if let manufacturerDataFilters = manufacturerData, !manufacturerDataFilters.isEmpty {
            guard let data = advertisement.manufacturerData, data.count >= 2 else {
                return false
            }
            let companyIdentifier = UInt16(data[0]) | (UInt16(data[1]) << 8)
            let payload = [UInt8](data.dropFirst(2))
            
            for filter in manufacturerDataFilters {
                if companyIdentifier != filter.companyIdentifier {
                    return false
                }
                if filter.dataPrefix.isEmpty {
                    continue
                }
                if payload.count < filter.dataPrefix.count {
                    return false
                }
                for index in filter.dataPrefix.indices {
                    if (payload[index] & filter.mask[index]) != (filter.dataPrefix[index] & filter.mask[index]) {
                        return false
                    }
                }
            }
        }
        
        return true
    }
}

public struct RequestDeviceOptions {
    public var filters: [ScanFilter]
    public var optionalServices: Set<CBUUID>
    public var acceptAllDevices: Bool
    
    public var allowedServices: Set<CBUUID> {
        var services = optionalServices
        for filter in filters {
            if let required = filter.services {
                services.formUnion(required)
            }
        }
        return services
    }
    
    public var scanServiceUUIDs: [CBUUID]? {
        if acceptAllDevices {
            return nil
        }
        let allHaveServices = filters.allSatisfy { !($0.services?.isEmpty ?? true) }
        guard allHaveServices else { return nil }
        var uuids = Set<CBUUID>()
        for filter in filters {
            if let services = filter.services {
                uuids.formUnion(services)
            }
        }
        return uuids.isEmpty ? nil : Array(uuids)
    }
    
    public static func parse(_ raw: Any?) throws -> RequestDeviceOptions {
        guard let dictionary = raw as? [String: Any] else {
            throw DOMError.typeError("requestDevice() requires an options argument")
        }
        
        let acceptAllDevices = dictionary["acceptAllDevices"] as? Bool ?? false
        
        var filters: [ScanFilter] = []
        if let rawFilters = dictionary["filters"] as? [Any] {
            filters = try rawFilters.map { try parseFilter($0) }
        }
        
        if acceptAllDevices {
            if !filters.isEmpty {
                throw DOMError.typeError("filters must not be present when acceptAllDevices is true")
            }
        } else {
            if filters.isEmpty {
                throw DOMError.typeError("filters must be a non-empty array unless acceptAllDevices is true")
            }
            if filters.contains(where: \.isEmpty) {
                throw DOMError.typeError("A filter must restrict devices with at least one name, namePrefix, services, or manufacturerData constraint")
            }
        }
        
        var optionalServices = Set<CBUUID>()
        if let rawOptional = dictionary["optionalServices"] as? [Any] {
            for item in rawOptional {
                guard let uuid = BluetoothUUID.parse(item) else {
                    throw DOMError.typeError("Invalid optionalServices UUID")
                }
                optionalServices.insert(uuid)
            }
        }
        
        return RequestDeviceOptions(
            filters: filters,
            optionalServices: optionalServices,
            acceptAllDevices: acceptAllDevices
        )
    }
    
    private static func parseFilter(_ raw: Any) throws -> ScanFilter {
        guard let dictionary = raw as? [String: Any] else {
            throw DOMError.typeError("Invalid Bluetooth LE scan filter")
        }
        
        var filter = ScanFilter()
        if let name = dictionary["name"] as? String {
            filter.name = name
        }
        if let namePrefix = dictionary["namePrefix"] as? String {
            filter.namePrefix = namePrefix
        }
        if let services = dictionary["services"] as? [Any] {
            var parsed = Set<CBUUID>()
            for item in services {
                guard let uuid = BluetoothUUID.parse(item) else {
                    throw DOMError.typeError("Invalid service UUID in filter")
                }
                parsed.insert(uuid)
            }
            filter.services = parsed
        }
        if let manufacturerData = dictionary["manufacturerData"] as? [Any] {
            filter.manufacturerData = try manufacturerData.map { try parseManufacturerDataFilter($0) }
        }
        return filter
    }
    
    private static func parseManufacturerDataFilter(_ raw: Any) throws -> ManufacturerDataFilter {
        guard let dictionary = raw as? [String: Any] else {
            throw DOMError.typeError("Invalid manufacturerData filter")
        }
        guard let company = intValue(dictionary["companyIdentifier"]) else {
            throw DOMError.typeError("manufacturerData.companyIdentifier is required")
        }
        
        let dataPrefix = byteArray(dictionary["dataPrefix"]) ?? []
        let mask = byteArray(dictionary["mask"]) ?? Array(repeating: 0xFF, count: dataPrefix.count)
        if mask.count != dataPrefix.count {
            throw DOMError.typeError("manufacturerData mask length must match dataPrefix length")
        }
        
        return ManufacturerDataFilter(
            companyIdentifier: UInt16(truncatingIfNeeded: company),
            dataPrefix: dataPrefix,
            mask: mask
        )
    }
    
    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }
    
    private static func byteArray(_ value: Any?) -> [UInt8]? {
        guard let value = value else { return nil }
        if let bytes = value as? [UInt8] { return bytes }
        if let ints = value as? [Int] { return ints.map { UInt8(truncatingIfNeeded: $0) } }
        if let numbers = value as? [NSNumber] { return numbers.map { $0.uint8Value } }
        return nil
    }
}

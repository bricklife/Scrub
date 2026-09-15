#if os(iOS) || os(visionOS)
import CoreBluetooth
import UIKit
import WebBluetoothCore

struct BluetoothDeviceInfo {
    let id: String
    let name: String?
    
    var dictionary: [String: Any] {
        var result: [String: Any] = ["id": id]
        result["name"] = name ?? NSNull()
        return result
    }
}

final class BluetoothCentral: NSObject {
    
    var onDisconnect: ((String) -> Void)?
    var onValueChanged: ((String, [UInt8]) -> Void)?
    var onAvailabilityChanged: ((Bool) -> Void)?
    var onBluetoothFailed: ((WebBluetoothError) -> Void)?
    
    private let queue = DispatchQueue(label: "WebBluetoothKit.central")
    private lazy var central = CBCentralManager(delegate: self, queue: queue)
    
    private var readyWaiters: [(Result<Void, DOMError>) -> Void] = []
    
    private var request: DeviceRequest?
    private weak var chooser: DeviceChooserViewController?
    
    private var devices: [UUID: DeviceRecord] = [:]
    private var services: [String: ServiceRecord] = [:]
    private var characteristics: [String: CharacteristicRecord] = [:]
    
    private var connectWaiters: [UUID: [(Result<Void, DOMError>) -> Void]] = [:]
    private var connectTimeouts: [UUID: DispatchWorkItem] = [:]
    private var serviceDiscoveryWaiters: [UUID: [(Result<Void, DOMError>) -> Void]] = [:]
    private var characteristicDiscoveryWaiters: [ObjectIdentifier: [(Result<Void, DOMError>) -> Void]] = [:]
    private var readWaiters: [ObjectIdentifier: [(Result<Data, DOMError>) -> Void]] = [:]
    private var writeWaiters: [ObjectIdentifier: [(Result<Void, DOMError>) -> Void]] = [:]
    private var notifyWaiters: [ObjectIdentifier: [(Result<Void, DOMError>) -> Void]] = [:]
    
    private struct DeviceRecord {
        let peripheral: CBPeripheral
        var allowedServices: Set<CBUUID>
        var generation: Int = 0
        var name: String?
    }
    
    private struct ServiceRecord {
        let id: String
        let deviceId: UUID
        let service: CBService
    }
    
    private struct CharacteristicRecord {
        let id: String
        let deviceId: UUID
        let characteristic: CBCharacteristic
    }
    
    private struct DeviceRequest {
        let options: RequestDeviceOptions
        let completion: (Result<BluetoothDeviceInfo, DOMError>) -> Void
    }
    
    func getAvailability(completion: @escaping (Bool) -> Void) {
        whenReady { result in
            switch result {
            case .success:
                completion(self.central.state == .poweredOn)
            case .failure:
                completion(false)
            }
        }
    }
    
    func requestDevice(
        options: RequestDeviceOptions,
        presenter: UIViewController,
        completion: @escaping (Result<BluetoothDeviceInfo, DOMError>) -> Void
    ) {
        whenReady { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                if self.request != nil {
                    completion(.failure(.invalidState("A device chooser is already open")))
                    return
                }
                self.startRequest(options: options, presenter: presenter, completion: completion)
            }
        }
    }
    
    func connect(deviceId: String, completion: @escaping (Result<Void, DOMError>) -> Void) {
        queue.async {
            guard let uuid = UUID(uuidString: deviceId), let record = self.devices[uuid] else {
                completion(.failure(.notFound("Unknown Bluetooth device")))
                return
            }
            let peripheral = record.peripheral
            switch peripheral.state {
            case .connected:
                if peripheral.services != nil {
                    completion(.success(()))
                } else {
                    self.waitForServices(uuid, completion: completion)
                    peripheral.discoverServices(nil)
                }
            case .connecting:
                self.connectWaiters[uuid, default: []].append(completion)
            default:
                self.connectWaiters[uuid, default: []].append(completion)
                self.scheduleConnectTimeout(uuid)
                self.central.connect(peripheral, options: nil)
            }
        }
    }
    
    func disconnect(deviceId: String) {
        queue.async {
            guard let uuid = UUID(uuidString: deviceId), let record = self.devices[uuid] else { return }
            if record.peripheral.state != .disconnected {
                self.central.cancelPeripheralConnection(record.peripheral)
            }
        }
    }
    
    func getPrimaryServices(
        deviceId: String,
        service: Any?,
        completion: @escaping (Result<[[String: Any]], DOMError>) -> Void
    ) {
        queue.async {
            do {
                let uuid = try self.requireDevice(deviceId)
                let record = self.devices[uuid]!
                try self.requireConnected(record.peripheral)
                let wanted = try self.parseOptionalUUID(service)
                if let wanted = wanted {
                    try self.requireAllowed(wanted, on: record, access: .read)
                }
                
                self.ensureServices(uuid) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        guard let record = self.devices[uuid], let services = record.peripheral.services else {
                            completion(.failure(.network("GATT services are no longer available")))
                            return
                        }
                        let infos = services.compactMap { cbService -> [String: Any]? in
                            if let wanted = wanted, cbService.uuid != wanted {
                                return nil
                            }
                            if !self.isAllowed(cbService.uuid, on: record) {
                                return nil
                            }
                            if GATTBlocklist.isBlocked(cbService.uuid, access: .read) {
                                return nil
                            }
                            return self.serviceInfo(cbService, deviceId: uuid, record: record)
                        }
                        if wanted != nil && infos.isEmpty {
                            completion(.failure(.notFound("No matching service found")))
                        } else {
                            completion(.success(infos))
                        }
                    }
                }
            } catch let error as DOMError {
                completion(.failure(error))
            } catch {
                completion(.failure(.network(error.localizedDescription)))
            }
        }
    }
    
    func getCharacteristics(
        serviceId: String,
        characteristic: Any?,
        completion: @escaping (Result<[[String: Any]], DOMError>) -> Void
    ) {
        queue.async {
            do {
                guard let serviceRecord = self.services[serviceId] else {
                    throw DOMError.invalidState("GATT service no longer exists")
                }
                guard let device = self.devices[serviceRecord.deviceId] else {
                    throw DOMError.network("GATT Server is disconnected")
                }
                try self.requireConnected(device.peripheral)
                try self.requireAllowed(serviceRecord.service.uuid, on: device, access: .read)
                
                let wanted = try self.parseOptionalUUID(characteristic)
                if let wanted = wanted {
                    try self.requireCharacteristicAccess(wanted, access: .read)
                }
                
                self.ensureCharacteristics(serviceRecord) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        guard let characteristics = serviceRecord.service.characteristics else {
                            completion(.failure(.network("GATT characteristics are no longer available")))
                            return
                        }
                        let infos = characteristics.compactMap { cbCharacteristic -> [String: Any]? in
                            if let wanted = wanted, cbCharacteristic.uuid != wanted {
                                return nil
                            }
                            if GATTBlocklist.isBlocked(cbCharacteristic.uuid, access: .read) {
                                return nil
                            }
                            return self.characteristicInfo(cbCharacteristic, serviceId: serviceId, deviceId: serviceRecord.deviceId)
                        }
                        if wanted != nil && infos.isEmpty {
                            completion(.failure(.notFound("No matching characteristic found")))
                        } else {
                            completion(.success(infos))
                        }
                    }
                }
            } catch let error as DOMError {
                completion(.failure(error))
            } catch {
                completion(.failure(.network(error.localizedDescription)))
            }
        }
    }
    
    func readValue(characteristicId: String, completion: @escaping (Result<[UInt8], DOMError>) -> Void) {
        queue.async {
            do {
                let record = try self.requireCharacteristic(characteristicId)
                let device = try self.requireConnectedDevice(record.deviceId)
                try self.requireAllowed(record.characteristic.service?.uuid, on: device, access: .read)
                try self.requireCharacteristicAccess(record.characteristic.uuid, access: .read)
                guard record.characteristic.properties.contains(.read) else {
                    throw DOMError.notSupported("Characteristic does not support read")
                }
                
                self.readWaiters[ObjectIdentifier(record.characteristic), default: []].append { result in
                    completion(result.map { [UInt8]($0) })
                }
                device.peripheral.readValue(for: record.characteristic)
            } catch let error as DOMError {
                completion(.failure(error))
            } catch {
                completion(.failure(.network(error.localizedDescription)))
            }
        }
    }
    
    func writeValue(
        characteristicId: String,
        bytes: [UInt8],
        withResponse: Bool?,
        completion: @escaping (Result<Void, DOMError>) -> Void
    ) {
        queue.async {
            do {
                let record = try self.requireCharacteristic(characteristicId)
                let device = try self.requireConnectedDevice(record.deviceId)
                try self.requireAllowed(record.characteristic.service?.uuid, on: device, access: .write)
                try self.requireCharacteristicAccess(record.characteristic.uuid, access: .write)
                
                let writeType = try self.writeType(for: record.characteristic, requested: withResponse)
                let data = Data(bytes)
                
                if writeType == .withResponse {
                    self.writeWaiters[ObjectIdentifier(record.characteristic), default: []].append(completion)
                    device.peripheral.writeValue(data, for: record.characteristic, type: writeType)
                } else {
                    device.peripheral.writeValue(data, for: record.characteristic, type: writeType)
                    completion(.success(()))
                }
            } catch let error as DOMError {
                completion(.failure(error))
            } catch {
                completion(.failure(.network(error.localizedDescription)))
            }
        }
    }
    
    func setNotify(
        characteristicId: String,
        enabled: Bool,
        completion: @escaping (Result<Void, DOMError>) -> Void
    ) {
        queue.async {
            do {
                let record = try self.requireCharacteristic(characteristicId)
                let device = try self.requireConnectedDevice(record.deviceId)
                try self.requireAllowed(record.characteristic.service?.uuid, on: device, access: .read)
                try self.requireCharacteristicAccess(record.characteristic.uuid, access: .read)
                let properties = record.characteristic.properties
                guard properties.contains(.notify) || properties.contains(.indicate) else {
                    throw DOMError.notSupported("Characteristic does not support notifications")
                }
                
                if record.characteristic.isNotifying == enabled {
                    completion(.success(()))
                    return
                }
                
                self.notifyWaiters[ObjectIdentifier(record.characteristic), default: []].append(completion)
                device.peripheral.setNotifyValue(enabled, for: record.characteristic)
            } catch let error as DOMError {
                completion(.failure(error))
            } catch {
                completion(.failure(.network(error.localizedDescription)))
            }
        }
    }
    
    func reset() {
        queue.async {
            self.failRequest(.network("The page was unloaded"))
            self.dismissChooser()
            
            for record in self.devices.values {
                if record.peripheral.state != .disconnected {
                    self.central.cancelPeripheralConnection(record.peripheral)
                }
            }
            
            self.rejectAll(&self.connectWaiters, .network("The page was unloaded"))
            self.rejectAll(&self.serviceDiscoveryWaiters, .network("The page was unloaded"))
            self.rejectAll(&self.characteristicDiscoveryWaiters, .network("The page was unloaded"))
            self.rejectAll(&self.readWaiters, .network("The page was unloaded"))
            self.rejectAll(&self.writeWaiters, .network("The page was unloaded"))
            self.rejectAll(&self.notifyWaiters, .network("The page was unloaded"))
            
            self.connectTimeouts.values.forEach { $0.cancel() }
            self.connectTimeouts.removeAll()
            self.devices.removeAll()
            self.services.removeAll()
            self.characteristics.removeAll()
        }
    }
    
    private func whenReady(completion: @escaping (Result<Void, DOMError>) -> Void) {
        queue.async {
            switch self.central.state {
            case .poweredOn:
                completion(.success(()))
            case .poweredOff:
                self.notifyFailure(.bluetoothIsPoweredOff)
                completion(.failure(.network("Bluetooth adapter is not available")))
            case .unauthorized:
                self.notifyFailure(.bluetoothIsUnauthorized)
                completion(.failure(.security("Bluetooth permission is denied")))
            case .unsupported:
                self.notifyFailure(.bluetoothIsUnsupported)
                completion(.failure(.notSupported("Bluetooth is not supported")))
            default:
                self.readyWaiters.append(completion)
            }
        }
    }
    
    private func startRequest(
        options: RequestDeviceOptions,
        presenter: UIViewController,
        completion: @escaping (Result<BluetoothDeviceInfo, DOMError>) -> Void
    ) {
        request = DeviceRequest(options: options, completion: completion)
        
        DispatchQueue.main.async {
            let chooser = DeviceChooserViewController()
            chooser.onSelect = { [weak self] id in
                self?.queue.async {
                    self?.completeRequest(selecting: id)
                }
            }
            chooser.onCancel = { [weak self] in
                self?.queue.async {
                    self?.failRequest(.notFound("User cancelled the requestDevice() chooser."))
                }
            }
            
            let navigation = UINavigationController(rootViewController: chooser)
            navigation.modalPresentationStyle = .formSheet
            self.chooser = chooser
            
            let presenterToUse = Self.topViewController(from: presenter)
            presenterToUse.present(navigation, animated: true)
            
            self.queue.async {
                self.startScan(options: options)
            }
        }
    }
    
    private func startScan(options: RequestDeviceOptions) {
        guard central.state == .poweredOn else { return }
        
        let services = options.scanServiceUUIDs
        if let services = services, !services.isEmpty {
            for peripheral in central.retrieveConnectedPeripherals(withServices: services) {
                consider(peripheral: peripheral, advertisementData: [:])
            }
        }
        
        central.scanForPeripherals(
            withServices: services,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    private func consider(peripheral: CBPeripheral, advertisementData: [String: Any]) {
        guard let request = request else { return }
        
        let advertisement = Advertisement(peripheral: peripheral, advertisementData: advertisementData)
        if !request.options.acceptAllDevices {
            guard request.options.filters.contains(where: { $0.matches(advertisement) }) else {
                return
            }
        }
        
        var record = devices[peripheral.identifier] ?? DeviceRecord(
            peripheral: peripheral,
            allowedServices: [],
            name: advertisement.name
        )
        record.allowedServices.formUnion(request.options.allowedServices)
        record.name = advertisement.name ?? record.name ?? peripheral.name
        devices[peripheral.identifier] = record
        peripheral.delegate = self
        
        let displayName = record.name?.isEmpty == false
            ? record.name!
            : NSLocalizedString("Unknown or Unsupported Device", bundle: .module, comment: "")
        let id = peripheral.identifier
        DispatchQueue.main.async {
            self.chooser?.updateDevice(id: id, name: displayName)
        }
    }
    
    private func completeRequest(selecting id: UUID) {
        guard let request = request else { return }
        central.stopScan()
        self.request = nil
        chooser = nil
        
        guard var record = devices[id] else {
            request.completion(.failure(.notFound("Selected device is no longer available")))
            return
        }
        record.allowedServices.formUnion(request.options.allowedServices)
        devices[id] = record
        request.completion(.success(BluetoothDeviceInfo(id: id.uuidString, name: record.name)))
    }
    
    private func failRequest(_ error: DOMError) {
        central.stopScan()
        if let request = request {
            self.request = nil
            request.completion(.failure(error))
        }
        dismissChooser()
    }
    
    private func dismissChooser() {
        DispatchQueue.main.async {
            self.chooser?.dismiss(animated: true)
            self.chooser = nil
        }
    }
    
    private func scheduleConnectTimeout(_ id: UUID) {
        connectTimeouts[id]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, let waiters = self.connectWaiters.removeValue(forKey: id), !waiters.isEmpty else {
                return
            }
            if let peripheral = self.devices[id]?.peripheral {
                self.central.cancelPeripheralConnection(peripheral)
            }
            waiters.forEach { $0(.failure(.network("Connection timed out"))) }
        }
        connectTimeouts[id] = work
        queue.asyncAfter(deadline: .now() + 30, execute: work)
    }
    
    private func finishConnect(_ id: UUID, _ result: Result<Void, DOMError>) {
        connectTimeouts.removeValue(forKey: id)?.cancel()
        let waiters = connectWaiters.removeValue(forKey: id) ?? []
        waiters.forEach { $0(result) }
    }
    
    private func waitForServices(_ id: UUID, completion: @escaping (Result<Void, DOMError>) -> Void) {
        serviceDiscoveryWaiters[id, default: []].append(completion)
    }
    
    private func ensureServices(_ id: UUID, completion: @escaping (Result<Void, DOMError>) -> Void) {
        guard let record = devices[id] else {
            completion(.failure(.notFound("Unknown Bluetooth device")))
            return
        }
        if record.peripheral.services != nil {
            completion(.success(()))
            return
        }
        waitForServices(id, completion: completion)
        record.peripheral.discoverServices(nil)
    }
    
    private func ensureCharacteristics(
        _ serviceRecord: ServiceRecord,
        completion: @escaping (Result<Void, DOMError>) -> Void
    ) {
        if serviceRecord.service.characteristics != nil {
            completion(.success(()))
            return
        }
        guard let device = devices[serviceRecord.deviceId] else {
            completion(.failure(.network("GATT Server is disconnected")))
            return
        }
        let key = ObjectIdentifier(serviceRecord.service)
        characteristicDiscoveryWaiters[key, default: []].append(completion)
        device.peripheral.discoverCharacteristics(nil, for: serviceRecord.service)
    }
    
    private func invalidateAttributes(for id: UUID) {
        services = services.filter { $0.value.deviceId != id }
        characteristics = characteristics.filter { $0.value.deviceId != id }
        if var record = devices[id] {
            record.generation += 1
            devices[id] = record
        }
    }
    
    private func serviceInfo(_ service: CBService, deviceId: UUID, record: DeviceRecord) -> [String: Any] {
        let existing = services.first { $0.value.service === service }?.value
        if let existing = existing {
            return [
                "id": existing.id,
                "uuid": BluetoothUUID.canonicalString(service.uuid),
                "isPrimary": service.isPrimary,
                "deviceId": deviceId.uuidString
            ]
        }
        
        let index = service.peripheral?.services?.firstIndex(where: { $0 === service }) ?? services.count
        let id = "\(deviceId.uuidString)#\(record.generation)|\(BluetoothUUID.canonicalString(service.uuid))|\(index)"
        services[id] = ServiceRecord(id: id, deviceId: deviceId, service: service)
        return [
            "id": id,
            "uuid": BluetoothUUID.canonicalString(service.uuid),
            "isPrimary": service.isPrimary,
            "deviceId": deviceId.uuidString
        ]
    }
    
    private func characteristicInfo(
        _ characteristic: CBCharacteristic,
        serviceId: String,
        deviceId: UUID
    ) -> [String: Any] {
        if let existing = characteristics.first(where: { $0.value.characteristic === characteristic })?.value {
            return characteristicDictionary(existing.id, characteristic, serviceId: serviceId)
        }
        
        let siblings = characteristic.service?.characteristics ?? []
        let index = siblings.firstIndex(where: { $0 === characteristic }) ?? characteristics.count
        let generation = devices[deviceId]?.generation ?? 0
        let id = "\(serviceId)#\(generation)|\(BluetoothUUID.canonicalString(characteristic.uuid))|\(index)"
        characteristics[id] = CharacteristicRecord(id: id, deviceId: deviceId, characteristic: characteristic)
        return characteristicDictionary(id, characteristic, serviceId: serviceId)
    }
    
    private func characteristicDictionary(
        _ id: String,
        _ characteristic: CBCharacteristic,
        serviceId: String
    ) -> [String: Any] {
        let properties = characteristic.properties
        return [
            "id": id,
            "uuid": BluetoothUUID.canonicalString(characteristic.uuid),
            "serviceId": serviceId,
            "properties": [
                "broadcast": properties.contains(.broadcast),
                "read": properties.contains(.read),
                "writeWithoutResponse": properties.contains(.writeWithoutResponse),
                "write": properties.contains(.write),
                "notify": properties.contains(.notify),
                "indicate": properties.contains(.indicate),
                "authenticatedSignedWrites": properties.contains(.authenticatedSignedWrites),
                "reliableWrite": false,
                "writableAuxiliaries": false
            ]
        ]
    }
    
    private func requireDevice(_ deviceId: String) throws -> UUID {
        guard let uuid = UUID(uuidString: deviceId), devices[uuid] != nil else {
            throw DOMError.notFound("Unknown Bluetooth device")
        }
        return uuid
    }
    
    private func requireConnectedDevice(_ id: UUID) throws -> DeviceRecord {
        guard let record = devices[id] else {
            throw DOMError.notFound("Unknown Bluetooth device")
        }
        try requireConnected(record.peripheral)
        return record
    }
    
    private func requireConnected(_ peripheral: CBPeripheral) throws {
        guard peripheral.state == .connected else {
            throw DOMError.network("GATT Server is disconnected. Cannot perform GATT operations.")
        }
    }
    
    private func requireCharacteristic(_ id: String) throws -> CharacteristicRecord {
        guard let record = characteristics[id] else {
            throw DOMError.invalidState("GATT characteristic no longer exists")
        }
        return record
    }
    
    private func requireAllowed(_ uuid: CBUUID?, on device: DeviceRecord, access: GATTAccess) throws {
        guard let uuid = uuid else {
            throw DOMError.security("Missing service UUID")
        }
        if GATTBlocklist.isBlocked(uuid, access: access) {
            throw DOMError.security("Service is blocklisted")
        }
        if !isAllowed(uuid, on: device) {
            throw DOMError.security("Origin is not allowed to access this service")
        }
    }
    
    private func isAllowed(_ uuid: CBUUID, on device: DeviceRecord) -> Bool {
        device.allowedServices.contains(uuid)
    }
    
    private func requireCharacteristicAccess(_ uuid: CBUUID, access: GATTAccess) throws {
        if GATTBlocklist.isBlocked(uuid, access: access) {
            throw DOMError.security("Characteristic is blocklisted")
        }
    }
    
    private func parseOptionalUUID(_ value: Any?) throws -> CBUUID? {
        guard let value = value, !(value is NSNull) else { return nil }
        guard let uuid = BluetoothUUID.parse(value) else {
            throw DOMError.typeError("Invalid UUID")
        }
        return uuid
    }
    
    private func writeType(for characteristic: CBCharacteristic, requested: Bool?) throws -> CBCharacteristicWriteType {
        let canWith = characteristic.properties.contains(.write)
        let canWithout = characteristic.properties.contains(.writeWithoutResponse)
        if let requested = requested {
            if requested {
                guard canWith else { throw DOMError.notSupported("Characteristic does not support write with response") }
                return .withResponse
            } else {
                guard canWithout else { throw DOMError.notSupported("Characteristic does not support write without response") }
                return .withoutResponse
            }
        }
        if canWithout { return .withoutResponse }
        if canWith { return .withResponse }
        throw DOMError.notSupported("Characteristic does not support write")
    }
    
    private func notifyFailure(_ error: WebBluetoothError) {
        DispatchQueue.main.async {
            self.onBluetoothFailed?(error)
        }
    }
    
    private func rejectAll<Key>(_ waiters: inout [Key: [(Result<Void, DOMError>) -> Void]], _ error: DOMError) {
        let pending = waiters
        waiters.removeAll()
        pending.values.flatMap { $0 }.forEach { $0(.failure(error)) }
    }
    
    private func rejectAll<Key>(_ waiters: inout [Key: [(Result<Data, DOMError>) -> Void]], _ error: DOMError) {
        let pending = waiters
        waiters.removeAll()
        pending.values.flatMap { $0 }.forEach { $0(.failure(error)) }
    }
    
    private static func topViewController(from base: UIViewController) -> UIViewController {
        if let presented = base.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = base as? UINavigationController, let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return base
    }
}

extension BluetoothCentral: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let available = central.state == .poweredOn
        DispatchQueue.main.async {
            self.onAvailabilityChanged?(available)
        }
        
        let waiters = readyWaiters
        readyWaiters.removeAll()
        switch central.state {
        case .poweredOn:
            waiters.forEach { $0(.success(())) }
        case .poweredOff:
            notifyFailure(.bluetoothIsPoweredOff)
            waiters.forEach { $0(.failure(.network("Bluetooth adapter is not available"))) }
            failRequest(.network("Bluetooth adapter is not available"))
        case .unauthorized:
            notifyFailure(.bluetoothIsUnauthorized)
            waiters.forEach { $0(.failure(.security("Bluetooth permission is denied"))) }
            failRequest(.security("Bluetooth permission is denied"))
        case .unsupported:
            notifyFailure(.bluetoothIsUnsupported)
            waiters.forEach { $0(.failure(.notSupported("Bluetooth is not supported"))) }
            failRequest(.notSupported("Bluetooth is not supported"))
        default:
            readyWaiters.append(contentsOf: waiters)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        consider(peripheral: peripheral, advertisementData: advertisementData)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let message = error?.localizedDescription ?? "Failed to connect"
        finishConnect(peripheral.identifier, .failure(.network(message)))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        invalidateAttributes(for: peripheral.identifier)
        finishConnect(peripheral.identifier, .failure(.network("GATT Server disconnected")))
        if let waiters = serviceDiscoveryWaiters.removeValue(forKey: peripheral.identifier) {
            waiters.forEach { $0(.failure(.network("GATT Server disconnected"))) }
        }
        DispatchQueue.main.async {
            self.onDisconnect?(peripheral.identifier.uuidString)
        }
    }
}

extension BluetoothCentral: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let id = peripheral.identifier
        let waiters = serviceDiscoveryWaiters.removeValue(forKey: id) ?? []
        if let error = error {
            let domError = DOMError.network(error.localizedDescription)
            waiters.forEach { $0(.failure(domError)) }
            finishConnect(id, .failure(domError))
            return
        }
        waiters.forEach { $0(.success(())) }
        finishConnect(id, .success(()))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let key = ObjectIdentifier(service)
        let waiters = characteristicDiscoveryWaiters.removeValue(forKey: key) ?? []
        if let error = error {
            waiters.forEach { $0(.failure(.network(error.localizedDescription))) }
        } else {
            waiters.forEach { $0(.success(())) }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = ObjectIdentifier(characteristic)
        let waiters = readWaiters.removeValue(forKey: key) ?? []
        if let error = error {
            waiters.forEach { $0(.failure(.network(error.localizedDescription))) }
            return
        }
        let data = characteristic.value ?? Data()
        waiters.forEach { $0(.success(data)) }
        
        if characteristic.isNotifying, let record = characteristics.first(where: { $0.value.characteristic === characteristic })?.value {
            let bytes = [UInt8](data)
            DispatchQueue.main.async {
                self.onValueChanged?(record.id, bytes)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = ObjectIdentifier(characteristic)
        let waiters = writeWaiters.removeValue(forKey: key) ?? []
        if let error = error {
            waiters.forEach { $0(.failure(.network(error.localizedDescription))) }
        } else {
            waiters.forEach { $0(.success(())) }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        let key = ObjectIdentifier(characteristic)
        let waiters = notifyWaiters.removeValue(forKey: key) ?? []
        if let error = error {
            waiters.forEach { $0(.failure(.network(error.localizedDescription))) }
        } else {
            waiters.forEach { $0(.success(())) }
        }
    }
}
#endif

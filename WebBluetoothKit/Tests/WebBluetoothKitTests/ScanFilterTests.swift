import CoreBluetooth
import XCTest
@testable import WebBluetoothCore

final class ScanFilterTests: XCTestCase {
    
    func testEmptyFilter() {
        XCTAssertTrue(ScanFilter().isEmpty)
        XCTAssertTrue(ScanFilter(name: "", namePrefix: "", services: [], manufacturerData: []).isEmpty)
        XCTAssertFalse(ScanFilter(name: "micro:bit").isEmpty)
        XCTAssertFalse(ScanFilter(namePrefix: "LEGO").isEmpty)
        XCTAssertFalse(ScanFilter(services: [CBUUID(string: "180D")]).isEmpty)
    }
    
    func testNameMustMatchExactly() {
        let filter = ScanFilter(name: "micro:bit")
        XCTAssertTrue(filter.matches(Advertisement(name: "micro:bit", serviceUUIDs: [], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: "micro:bit [pqr]", serviceUUIDs: [], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: nil)))
    }
    
    func testNamePrefix() {
        let filter = ScanFilter(namePrefix: "BBC micro:bit")
        XCTAssertTrue(filter.matches(Advertisement(name: "BBC micro:bit [pqr]", serviceUUIDs: [], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: "micro:bit", serviceUUIDs: [], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: nil)))
    }
    
    func testServicesMustBeSubset() {
        let heartRate = CBUUID(string: "180D")
        let battery = CBUUID(string: "180F")
        let filter = ScanFilter(services: [heartRate, battery])
        
        XCTAssertTrue(filter.matches(Advertisement(
            name: "watch",
            serviceUUIDs: [heartRate, battery, CBUUID(string: "180A")],
            manufacturerData: nil
        )))
        XCTAssertFalse(filter.matches(Advertisement(
            name: "watch",
            serviceUUIDs: [heartRate],
            manufacturerData: nil
        )))
    }
    
    func testManufacturerDataMatchesCompanyIdentifierAndMaskedPrefix() {
        // Company ID 0x00E0, payload 0x11 0x2A. Filter requires low nybble of first byte == 0x1
        // and second byte == 0x2A, matching the Web Bluetooth dataPrefix/mask example.
        let advertisementData = Data([0xE0, 0x00, 0x11, 0x2A, 0xFF])
        let filter = ScanFilter(manufacturerData: [
            ManufacturerDataFilter(
                companyIdentifier: 0x00E0,
                dataPrefix: [0x01, 0x2A],
                mask: [0x0F, 0xFF]
            )
        ])
        
        XCTAssertTrue(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: advertisementData)))
    }
    
    func testManufacturerDataRejectsWrongCompany() {
        let advertisementData = Data([0xE1, 0x00, 0x01, 0x2A])
        let filter = ScanFilter(manufacturerData: [
            ManufacturerDataFilter(
                companyIdentifier: 0x00E0,
                dataPrefix: [0x01, 0x2A],
                mask: [0xFF, 0xFF]
            )
        ])
        
        XCTAssertFalse(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: advertisementData)))
    }
    
    func testManufacturerDataRejectsShortPayload() {
        let advertisementData = Data([0xE0, 0x00, 0x01])
        let filter = ScanFilter(manufacturerData: [
            ManufacturerDataFilter(
                companyIdentifier: 0x00E0,
                dataPrefix: [0x01, 0x2A],
                mask: [0xFF, 0xFF]
            )
        ])
        
        XCTAssertFalse(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: advertisementData)))
    }
    
    func testManufacturerDataWithEmptyPrefixMatchesCompanyOnly() {
        let advertisementData = Data([0xE0, 0x00])
        let filter = ScanFilter(manufacturerData: [
            ManufacturerDataFilter(companyIdentifier: 0x00E0, dataPrefix: [], mask: [])
        ])
        
        XCTAssertTrue(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: advertisementData)))
        XCTAssertFalse(filter.matches(Advertisement(name: nil, serviceUUIDs: [], manufacturerData: nil)))
    }
    
    func testCombinedFilterRequiresEveryConstraint() {
        let heartRate = CBUUID(string: "180D")
        let filter = ScanFilter(namePrefix: "HR", services: [heartRate])
        
        XCTAssertTrue(filter.matches(Advertisement(name: "HR-Watch", serviceUUIDs: [heartRate], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: "HR-Watch", serviceUUIDs: [], manufacturerData: nil)))
        XCTAssertFalse(filter.matches(Advertisement(name: "Watch", serviceUUIDs: [heartRate], manufacturerData: nil)))
    }
}

import CoreBluetooth
import XCTest
@testable import WebBluetoothCore

final class RequestDeviceOptionsTests: XCTestCase {
    
    func testParseRequiresOptionsObject() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse(nil)) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
        XCTAssertThrowsError(try RequestDeviceOptions.parse("nope")) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testParseRejectsMissingFiltersUnlessAcceptAllDevices() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse([String: Any]())) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
        XCTAssertThrowsError(try RequestDeviceOptions.parse(["filters": []])) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testParseRejectsEmptyFilter() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse([
            "filters": [[String: Any]()]
        ])) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testParseRejectsFiltersWithAcceptAllDevices() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse([
            "acceptAllDevices": true,
            "filters": [["name": "x"]]
        ])) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testParseAcceptAllDevices() throws {
        let options = try RequestDeviceOptions.parse([
            "acceptAllDevices": true,
            "optionalServices": ["battery_service", 0x180D] as [Any]
        ])
        XCTAssertTrue(options.acceptAllDevices)
        XCTAssertTrue(options.filters.isEmpty)
        XCTAssertEqual(options.allowedServices, [CBUUID(string: "180F"), CBUUID(string: "180D")])
        XCTAssertNil(options.scanServiceUUIDs)
    }
    
    func testParseNameAndServiceFilters() throws {
        let options = try RequestDeviceOptions.parse([
            "filters": [
                ["name": "micro:bit"],
                ["services": ["heart_rate", "0000180f-0000-1000-8000-00805f9b34fb"]]
            ],
            "optionalServices": ["device_information"]
        ])
        
        XCTAssertFalse(options.acceptAllDevices)
        XCTAssertEqual(options.filters.count, 2)
        XCTAssertEqual(options.filters[0].name, "micro:bit")
        XCTAssertEqual(options.filters[1].services, [CBUUID(string: "180D"), CBUUID(string: "180F")])
        XCTAssertEqual(
            options.allowedServices,
            [CBUUID(string: "180D"), CBUUID(string: "180F"), CBUUID(string: "180A")]
        )
    }
    
    func testParseManufacturerDataFromJSNumbers() throws {
        let options = try RequestDeviceOptions.parse([
            "filters": [[
                "manufacturerData": [[
                    "companyIdentifier": NSNumber(value: 224),
                    "dataPrefix": [1, 42],
                    "mask": [15, 255]
                ]]
            ]]
        ])
        
        let filter = try XCTUnwrap(options.filters.first?.manufacturerData?.first)
        XCTAssertEqual(filter.companyIdentifier, 224)
        XCTAssertEqual(filter.dataPrefix, [1, 42])
        XCTAssertEqual(filter.mask, [15, 255])
    }
    
    func testParseDefaultMaskMatchesDataPrefixLength() throws {
        let options = try RequestDeviceOptions.parse([
            "filters": [[
                "manufacturerData": [[
                    "companyIdentifier": 17,
                    "dataPrefix": [1, 2, 3]
                ]]
            ]]
        ])
        
        let filter = try XCTUnwrap(options.filters.first?.manufacturerData?.first)
        XCTAssertEqual(filter.mask, [0xFF, 0xFF, 0xFF])
    }
    
    func testParseRejectsMaskLengthMismatch() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse([
            "filters": [[
                "manufacturerData": [[
                    "companyIdentifier": 17,
                    "dataPrefix": [1, 2],
                    "mask": [255]
                ]]
            ]]
        ])) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testParseRejectsInvalidOptionalService() {
        XCTAssertThrowsError(try RequestDeviceOptions.parse([
            "filters": [["name": "x"]],
            "optionalServices": ["not_a_service"]
        ])) { error in
            XCTAssertEqual((error as? DOMError)?.name, "TypeError")
        }
    }
    
    func testScanServiceUUIDsWhenEveryFilterHasServices() throws {
        let options = try RequestDeviceOptions.parse([
            "filters": [
                ["services": ["heart_rate"]],
                ["services": [0x180F]]
            ]
        ])
        XCTAssertEqual(
            Set(options.scanServiceUUIDs ?? []),
            [CBUUID(string: "180D"), CBUUID(string: "180F")]
        )
    }
    
    func testScanServiceUUIDsNilWhenAnyFilterIsNameOnly() throws {
        let options = try RequestDeviceOptions.parse([
            "filters": [
                ["name": "Foo"],
                ["services": ["heart_rate"]]
            ]
        ])
        XCTAssertNil(options.scanServiceUUIDs)
    }
}

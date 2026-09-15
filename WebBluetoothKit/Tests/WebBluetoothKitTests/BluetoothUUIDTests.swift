import CoreBluetooth
import XCTest
@testable import WebBluetoothCore

final class BluetoothUUIDTests: XCTestCase {
    
    func testCanonicalStringExpands16BitUUID() {
        let uuid = CBUUID(string: "180D")
        XCTAssertEqual(
            BluetoothUUID.canonicalString(uuid),
            "0000180d-0000-1000-8000-00805f9b34fb"
        )
    }
    
    func testCanonicalStringExpands32BitUUID() {
        let uuid = CBUUID(string: "0000180D")
        XCTAssertEqual(
            BluetoothUUID.canonicalString(uuid),
            "0000180d-0000-1000-8000-00805f9b34fb"
        )
    }
    
    func testCanonicalStringLowercases128BitUUID() {
        let uuid = CBUUID(string: "12345678-90AB-CDEF-1234-567890ABCDEF")
        XCTAssertEqual(
            BluetoothUUID.canonicalString(uuid),
            "12345678-90ab-cdef-1234-567890abcdef"
        )
    }
    
    func testParseAssignedServiceName() {
        let parsed = BluetoothUUID.parse("heart_rate")
        XCTAssertEqual(parsed, CBUUID(string: "180D"))
        XCTAssertEqual(parsed, CBUUID(string: "0000180d-0000-1000-8000-00805f9b34fb"))
    }
    
    func testParseAssignedCharacteristicName() {
        XCTAssertEqual(
            BluetoothUUID.parse("battery_level"),
            CBUUID(string: "2A19")
        )
    }
    
    func testParseIntegerAlias() {
        XCTAssertEqual(BluetoothUUID.parse(0x180F), CBUUID(string: "180F"))
        XCTAssertEqual(BluetoothUUID.parse(NSNumber(value: 0x180D)), CBUUID(string: "180D"))
    }
    
    func testParseUUIDString() {
        let full = "0000180f-0000-1000-8000-00805f9b34fb"
        XCTAssertEqual(BluetoothUUID.parse(full), CBUUID(string: "180F"))
        XCTAssertEqual(BluetoothUUID.parse(full.uppercased()), CBUUID(string: "180F"))
    }
    
    func testParseShortHexString() {
        XCTAssertEqual(BluetoothUUID.parse("180d"), CBUUID(string: "180D"))
    }
    
    func testParseRejectsBooleanNSNumber() {
        XCTAssertNil(BluetoothUUID.parse(NSNumber(value: true)))
        XCTAssertNil(BluetoothUUID.parse(NSNumber(value: false)))
    }
    
    func testParseRejectsUnknownName() {
        XCTAssertNil(BluetoothUUID.parse("not_a_real_service"))
        XCTAssertNil(BluetoothUUID.parse(""))
    }
}

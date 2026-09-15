import CoreBluetooth
import XCTest
@testable import WebBluetoothCore

final class GATTBlocklistTests: XCTestCase {
    
    func testHIDServiceIsFullyBlocked() {
        let hid = CBUUID(string: "1812")
        XCTAssertTrue(GATTBlocklist.isBlocked(hid, access: .read))
        XCTAssertTrue(GATTBlocklist.isBlocked(hid, access: .write))
        XCTAssertTrue(GATTBlocklist.isBlocked(CBUUID(string: "00001812-0000-1000-8000-00805f9b34fb"), access: .read))
    }
    
    func testSerialNumberStringIsFullyBlocked() {
        let serial = CBUUID(string: "2A25")
        XCTAssertTrue(GATTBlocklist.isBlocked(serial, access: .read))
        XCTAssertTrue(GATTBlocklist.isBlocked(serial, access: .write))
    }
    
    func testClientCharacteristicConfigurationBlocksWritesOnly() {
        let cccd = CBUUID(string: "2902")
        XCTAssertFalse(GATTBlocklist.isBlocked(cccd, access: .read))
        XCTAssertTrue(GATTBlocklist.isBlocked(cccd, access: .write))
    }
    
    func testPeripheralPrivacyFlagBlocksWritesOnly() {
        let flag = CBUUID(string: "2A02")
        XCTAssertFalse(GATTBlocklist.isBlocked(flag, access: .read))
        XCTAssertTrue(GATTBlocklist.isBlocked(flag, access: .write))
    }
    
    func testUnlistedUUIDIsNotBlocked() {
        let heartRate = CBUUID(string: "180D")
        XCTAssertFalse(GATTBlocklist.isBlocked(heartRate, access: .read))
        XCTAssertFalse(GATTBlocklist.isBlocked(heartRate, access: .write))
    }
}

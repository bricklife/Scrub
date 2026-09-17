import JavaScriptCore
import XCTest
@testable import WebBluetoothCore

final class InjectedJavaScriptTests: XCTestCase {
    
    private var context: JSContext!
    private var lastException: String?
    
    override func setUp() {
        super.setUp()
        lastException = nil
        context = JSContext()
        context.exceptionHandler = { [weak self] _, exception in
            self?.lastException = exception?.toString()
        }
        
        let harness = """
        globalThis.window = globalThis;
        globalThis.navigator = {};
        globalThis.webkit = {
            messageHandlers: {
                webBluetooth: {
                    postMessage: function(message) {
                        globalThis.__posted = globalThis.__posted || [];
                        globalThis.__posted.push(message);
                    }
                }
            }
        };
        if (typeof Event === 'undefined') {
            globalThis.Event = class Event {
                constructor(type) { this.type = type; }
            };
        }
        if (typeof EventTarget === 'undefined') {
            globalThis.EventTarget = class EventTarget {
                constructor() { this._listeners = {}; }
                addEventListener(type, listener) {
                    (this._listeners[type] = this._listeners[type] || []).push(listener);
                }
                dispatchEvent(event) {
                    (this._listeners[event.type] || []).forEach(function(listener) { listener(event); });
                    return true;
                }
            };
        }
        if (typeof CustomEvent === 'undefined') {
            globalThis.CustomEvent = class CustomEvent {
                constructor(type, init) {
                    this.type = type;
                    this.detail = init && init.detail;
                }
            };
        }
        if (typeof WeakRef === 'undefined') {
            globalThis.WeakRef = class WeakRef {
                constructor(value) { this._value = value; }
                deref() { return this._value; }
            };
        }
        if (typeof DOMException === 'undefined') {
            globalThis.DOMException = class DOMException extends Error {
                constructor(message, name) {
                    super(message);
                    this.name = name || 'Error';
                }
            };
        }
        """
        context.evaluateScript(harness)
        
        let source = WebBluetoothJavaScript.injectSource
        XCTAssertFalse(source.isEmpty, "inject.js should be bundled with WebBluetoothKit")
        context.evaluateScript(source)
    }
    
    func testInstallsNavigatorBluetoothAndBluetoothUUID() {
        XCTAssertEqual(context.evaluateScript("typeof navigator.bluetooth")?.toString(), "object")
        XCTAssertEqual(context.evaluateScript("typeof BluetoothUUID.getService")?.toString(), "function")
        XCTAssertEqual(context.evaluateScript("typeof WebBluetoothKit.coordinator")?.toString(), "object")
    }
    
    func testBluetoothUUIDCanonicalAndAssignedNames() {
        XCTAssertEqual(
            context.evaluateScript("BluetoothUUID.canonicalUUID(0x180D)")?.toString(),
            "0000180d-0000-1000-8000-00805f9b34fb"
        )
        XCTAssertEqual(
            context.evaluateScript("BluetoothUUID.getService('heart_rate')")?.toString(),
            "0000180d-0000-1000-8000-00805f9b34fb"
        )
        XCTAssertEqual(
            context.evaluateScript("BluetoothUUID.getCharacteristic('battery_level')")?.toString(),
            "00002a19-0000-1000-8000-00805f9b34fb"
        )
        XCTAssertEqual(
            context.evaluateScript("BluetoothUUID.getService('0000180F-0000-1000-8000-00805F9B34FB')")?.toString(),
            "0000180f-0000-1000-8000-00805f9b34fb"
        )
        XCTAssertEqual(
            context.evaluateScript("BluetoothUUID.getService(0x180F)")?.toString(),
            "0000180f-0000-1000-8000-00805f9b34fb"
        )
    }
    
    func testBluetoothUUIDRejectsUnknownName() {
        let result = context.evaluateScript("""
        (function() {
            try {
                BluetoothUUID.getService('not_a_real_service');
                return 'no-throw';
            } catch (error) {
                return error.name;
            }
        })()
        """)
        XCTAssertNil(lastException, lastException ?? "")
        XCTAssertEqual(result?.toString(), "TypeError")
    }
    
    func testToByteArrayHandlesTypedArraysAndOffsets() {
        let script = """
        (function() {
            const fromArray = WebBluetoothKit.toByteArray([1, 2, 3]);
            const fromUint8 = WebBluetoothKit.toByteArray(new Uint8Array([4, 5]));
            const buffer = new ArrayBuffer(4);
            const bytes = new Uint8Array(buffer);
            bytes.set([0, 9, 8, 7]);
            const fromView = WebBluetoothKit.toByteArray(new DataView(buffer, 1, 2));
            const fromOffsetArray = WebBluetoothKit.toByteArray(new Uint8Array(buffer, 1, 2));
            return JSON.stringify({ fromArray, fromUint8, fromView, fromOffsetArray });
        })()
        """
        XCTAssertEqual(
            context.evaluateScript(script)?.toString(),
            "{\"fromArray\":[1,2,3],\"fromUint8\":[4,5],\"fromView\":[9,8],\"fromOffsetArray\":[9,8]}"
        )
    }
    
    func testSerializeOptionsConvertsTypedArrays() {
        let script = """
        JSON.stringify(WebBluetoothKit.serializeOptions({
            filters: [{
                namePrefix: 'HR',
                services: ['heart_rate'],
                manufacturerData: [{
                    companyIdentifier: 224,
                    dataPrefix: new Uint8Array([1, 42]),
                    mask: new Uint8Array([15, 255])
                }]
            }],
            optionalServices: ['battery_service']
        }))
        """
        let json = context.evaluateScript(script)?.toString() ?? ""
        XCTAssertTrue(json.contains("\"namePrefix\":\"HR\""), json)
        XCTAssertTrue(json.contains("\"companyIdentifier\":224"), json)
        XCTAssertTrue(json.contains("\"dataPrefix\":[1,42]"), json)
        XCTAssertTrue(json.contains("\"mask\":[15,255]"), json)
        XCTAssertTrue(json.contains("\"optionalServices\":[\"battery_service\"]"), json)
    }
    
    func testCoordinatorSendPostsIncrementingRequestIds() {
        _ = context.evaluateScript("globalThis.__posted = []")
        _ = context.evaluateScript("WebBluetoothKit.coordinator.send('getAvailability')")
        _ = context.evaluateScript("WebBluetoothKit.coordinator.send('requestDevice', { options: { acceptAllDevices: true } })")
        let json = context.evaluateScript("JSON.stringify(globalThis.__posted)")?.toString() ?? ""
        XCTAssertTrue(json.contains("\"method\":\"getAvailability\""), json)
        XCTAssertTrue(json.contains("\"requestId\":0"), json)
        XCTAssertTrue(json.contains("\"method\":\"requestDevice\""), json)
        XCTAssertTrue(json.contains("\"requestId\":1"), json)
        XCTAssertTrue(json.contains("\"acceptAllDevices\":true"), json)
    }
    
    func testNativeErrorWrapsTypeErrorAndDOMException() {
        let json = context.evaluateScript("""
        (function() {
            function inspect(error) {
                try {
                    throw WebBluetoothKit.nativeError(error);
                } catch (caught) {
                    return {
                        name: caught.name,
                        message: caught.message,
                        isTypeError: caught instanceof TypeError,
                        isDOMException: typeof DOMException !== 'undefined' && caught instanceof DOMException
                    };
                }
            }
            return JSON.stringify({
                typeError: inspect({ name: 'TypeError', message: 'bad options' }),
                notFound: inspect({ name: 'NotFoundError', message: 'cancelled' })
            });
        })()
        """)?.toString() ?? ""
        XCTAssertTrue(json.contains("\"name\":\"TypeError\""), json)
        XCTAssertTrue(json.contains("\"isTypeError\":true"), json)
        XCTAssertTrue(json.contains("\"name\":\"NotFoundError\""), json)
        XCTAssertTrue(json.contains("\"isDOMException\":true"), json)
    }
}

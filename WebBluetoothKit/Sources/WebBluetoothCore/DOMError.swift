import Foundation

public struct DOMError: Error, Equatable {
    public let name: String
    public let message: String
    
    public var dictionary: [String: String] {
        ["name": name, "message": message]
    }
    
    public static func typeError(_ message: String) -> DOMError {
        DOMError(name: "TypeError", message: message)
    }
    
    public static func notFound(_ message: String) -> DOMError {
        DOMError(name: "NotFoundError", message: message)
    }
    
    public static func network(_ message: String) -> DOMError {
        DOMError(name: "NetworkError", message: message)
    }
    
    public static func invalidState(_ message: String) -> DOMError {
        DOMError(name: "InvalidStateError", message: message)
    }
    
    public static func security(_ message: String) -> DOMError {
        DOMError(name: "SecurityError", message: message)
    }
    
    public static func notSupported(_ message: String) -> DOMError {
        DOMError(name: "NotSupportedError", message: message)
    }
    
    public static func invalidModification(_ message: String) -> DOMError {
        DOMError(name: "InvalidModificationError", message: message)
    }
}

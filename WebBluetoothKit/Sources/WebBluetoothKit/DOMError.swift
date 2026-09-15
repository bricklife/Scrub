import Foundation

struct DOMError: Error {
    let name: String
    let message: String
    
    var dictionary: [String: String] {
        ["name": name, "message": message]
    }
    
    static func typeError(_ message: String) -> DOMError {
        DOMError(name: "TypeError", message: message)
    }
    
    static func notFound(_ message: String) -> DOMError {
        DOMError(name: "NotFoundError", message: message)
    }
    
    static func network(_ message: String) -> DOMError {
        DOMError(name: "NetworkError", message: message)
    }
    
    static func invalidState(_ message: String) -> DOMError {
        DOMError(name: "InvalidStateError", message: message)
    }
    
    static func security(_ message: String) -> DOMError {
        DOMError(name: "SecurityError", message: message)
    }
    
    static func notSupported(_ message: String) -> DOMError {
        DOMError(name: "NotSupportedError", message: message)
    }
    
    static func invalidModification(_ message: String) -> DOMError {
        DOMError(name: "InvalidModificationError", message: message)
    }
}

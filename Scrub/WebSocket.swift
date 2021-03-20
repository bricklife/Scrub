//
//  WebSocket.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation

public class WebSocket {
    
    let callback: (String) -> Void
    
    public init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }
    
    public func readStringMessage(continuation: @escaping (String?, _ opcode: Any, _ final: Bool) -> ()) {
    }
    
    public func sendStringMessage(string: String, final: Bool, completion: @escaping () -> ()) {
        self.callback(string)
        completion()
    }
    
    public func close() {
    }
}

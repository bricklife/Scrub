//
//  WebSocket.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation

class WebSocket {
    
    let callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }
    
    func readStringMessage(continuation: @escaping (String?, _ opcode: Any, _ final: Bool) -> ()) {
    }
    
    func sendStringMessage(string: String, final: Bool, completion: @escaping () -> ()) {
        self.callback(string)
        completion()
    }
    
    func close() {
    }
}

//
//  ScratchLink.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import Foundation

typealias uint8 = UInt8
typealias uint16 = UInt16
typealias uint32 = UInt32

public enum SerializationError: Error {
    case invalid(String)
    case internalError(String)
}

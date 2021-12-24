//
//  Bundle.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/25.
//

import Foundation

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle {
        return Bundle.main
    }
}
#endif

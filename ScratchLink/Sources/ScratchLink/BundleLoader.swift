//
//  BundleLoader.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/25.
//

import Foundation

class BundleLoader {
    
    static var bundle: Bundle {
#if SWIFT_PACKAGE && swift(>=5.3)
        return Bundle.module
#else
        return Bundle(for: self)
#endif
    }
}

//
//  ManagedAppConfig.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/27.
//

import Foundation

class ManagedAppConfig {
    
    static let shared = ManagedAppConfig()
    
    var configurations: [String : Any]? {
        return UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")
    }
    
    func value(forKey key: String) -> Any? {
        return configurations?[key]
    }
    
    func string(forKey key: String) -> String? {
        value(forKey: key) as? String
    }
    
    func rawRepresentable<V>(forKey key: String) -> V? where V: RawRepresentable, V.RawValue == String {
        return string(forKey: key).flatMap(V.init(rawValue:))
    }
}

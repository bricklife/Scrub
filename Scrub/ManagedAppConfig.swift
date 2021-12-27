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
    
    private var didChangeHandlers: [([String : Any]?) -> Void] = []
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(ManagedAppConfig.didChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
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
    
    func addDidChangeHandler(_ didChangeHandler: @escaping ([String : Any]?) -> Void) {
        didChangeHandlers.append(didChangeHandler)
    }
    
    @objc func didChange(_ notification: Notification) {
        let configurations = configurations
        for hander in didChangeHandlers {
            hander(configurations)
        }
    }
}

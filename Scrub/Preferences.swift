//
//  Preferences.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/17.
//

import Foundation
import Combine

class Preferences: ObservableObject {
    
    enum HomeUrl: String {
        case scratchHome
        case customUrl
        case documentsFolder
    }
    
    enum LaunchingUrl: String {
        case homeUrl
        case lastUrl
    }
    
    @Published var homeUrl: HomeUrl
    @Published var launchingUrl: LaunchingUrl
    @Published var customUrl: String?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        self.homeUrl = UserDefaults.standard.getEnum(forKey: "homeUrl") ?? .scratchHome
        self.launchingUrl = UserDefaults.standard.getEnum(forKey: "launchingUrl") ?? .lastUrl
        self.customUrl = UserDefaults.standard.string(forKey: "customUrl")
        
        $homeUrl.sink { (value) in
            UserDefaults.standard.setEnum(value, forKey: "homeUrl")
        }.store(in: &cancellables)
        $launchingUrl.sink { (value) in
            UserDefaults.standard.setEnum(value, forKey: "launchingUrl")
        }.store(in: &cancellables)
        $customUrl.sink { (value) in
            UserDefaults.standard.setValue(value, forKey: "$customUrl")
        }.store(in: &cancellables)
    }
}

extension UserDefaults {
    
    func getEnum<V>(forKey key: String) -> V? where V: RawRepresentable, V.RawValue == String {
        if let s = string(forKey: key), let v = V.init(rawValue: s) {
            return v
        }
        return nil
    }
    
    func setEnum<V>(_ value: V?, forKey key: String) where V: RawRepresentable, V.RawValue == String {
        setValue(value?.rawValue, forKey: key)
    }
}

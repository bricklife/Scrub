//
//  Preferences.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/17.
//

import Foundation
import Combine

private let ScratchHomeUrl = URL(string: "https://scratch.mit.edu/projects/editor/")!

class Preferences: ObservableObject {
    
    enum HomeUrl: String {
        case scratchHome
        case custom
        case documentsFolder
    }
    
    enum LaunchingUrl: String {
        case homeUrl
        case lastUrl
    }
    
    let initialUrl: URL
    
    @Published var homeUrl: HomeUrl
    @Published var launchingUrl: LaunchingUrl
    @Published var customUrl: String
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let homeUrl: HomeUrl = UserDefaults.standard.getEnum(forKey: "homeUrl") ?? .scratchHome
        let launchingUrl: LaunchingUrl = UserDefaults.standard.getEnum(forKey: "launchingUrl") ?? .lastUrl
        let customUrl: String = UserDefaults.standard.string(forKey: "customUrl") ?? ""
        
        switch homeUrl {
        case .scratchHome:
            self.initialUrl = ScratchHomeUrl
        case .custom:
            self.initialUrl = URL(string: customUrl) ?? ScratchHomeUrl
        case .documentsFolder:
            self.initialUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("index.html")
        }
        
        self.homeUrl = homeUrl
        self.launchingUrl = launchingUrl
        self.customUrl = customUrl
        
        $homeUrl.sink { (value) in
            UserDefaults.standard.setEnum(value, forKey: "homeUrl")
        }.store(in: &cancellables)
        $launchingUrl.sink { (value) in
            UserDefaults.standard.setEnum(value, forKey: "launchingUrl")
        }.store(in: &cancellables)
        $customUrl.sink { (value) in
            UserDefaults.standard.setValue(value, forKey: "customUrl")
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

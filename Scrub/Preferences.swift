//
//  Preferences.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/17.
//

import Foundation
import Combine

private let homeKey = "home"
private let customUrlKey = "customUrl"
private let didShowBluetoothParingDialogKey = "didShowBluetoothParingDialog"

@MainActor
class Preferences: ObservableObject {
    
    enum Home: String {
        case scratchHome
        case scratchEditor
        case scratchMyStuff
        case customUrl
        case documentsFolder
    }
    
    var home: Home {
        get {
            ManagedAppConfig.shared.rawRepresentable(forKey: homeKey)
            ?? UserDefaults.standard.rawRepresentable(forKey: homeKey)
            ?? .scratchEditor
        }
        set {
            if !isHomeLocked {
                UserDefaults.standard.setRawRepresentable(newValue, forKey: homeKey)
            }
        }
    }
    
    var isHomeLocked: Bool {
        ManagedAppConfig.shared.isSet(forKey: homeKey)
    }
    
    var customUrl: String {
        get {
            ManagedAppConfig.shared.string(forKey: customUrlKey)
            ?? UserDefaults.standard.string(forKey: customUrlKey)
            ?? ""
        }
        set {
            if !isCustomUrlLocked {
                UserDefaults.standard.setValue(newValue, forKey: customUrlKey)
            }
        }
    }
    
    var isCustomUrlLocked: Bool {
        ManagedAppConfig.shared.isSet(forKey: customUrlKey)
    }
    
    var didShowBluetoothParingDialog: Bool {
        get {
            UserDefaults.standard.bool(forKey: didShowBluetoothParingDialogKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: didShowBluetoothParingDialogKey)
        }
    }
    
    init() {
        migrate()
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
    
    private func migrate() {
        if let value = UserDefaults.standard.string(forKey: "homeUrl") {
            UserDefaults.standard.removeObject(forKey: "homeUrl")
            if value == "custom" {
                UserDefaults.standard.setValue(Home.customUrl.rawValue, forKey: homeKey)
            } else {
                UserDefaults.standard.setValue(value, forKey: homeKey)
            }
        }
    }
}

extension UserDefaults {
    
    func rawRepresentable<V>(forKey key: String) -> V? where V: RawRepresentable, V.RawValue == String {
        return string(forKey: key).flatMap(V.init(rawValue:))
    }
    
    func setRawRepresentable<V>(_ value: V?, forKey key: String) where V: RawRepresentable, V.RawValue == String {
        setValue(value?.rawValue, forKey: key)
    }
}

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
            UserDefaults.standard.rawRepresentable(forKey: homeKey) ?? .scratchEditor
        }
        set {
            if !isHomeLocked {
                UserDefaults.standard.setRawRepresentable(newValue, forKey: homeKey)
            }
        }
    }
    
    var isHomeLocked: Bool {
        return false
    }
    
    var customUrl: String {
        get {
            UserDefaults.standard.string(forKey: customUrlKey) ?? ""
        }
        set {
            if !isCustomUrlLocked {
                UserDefaults.standard.setValue(newValue, forKey: customUrlKey)
            }
        }
    }
    
    var isCustomUrlLocked: Bool {
        return false
    }
    
    var didShowBluetoothParingDialog: Bool {
        get {
            UserDefaults.standard.bool(forKey: didShowBluetoothParingDialogKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: didShowBluetoothParingDialogKey)
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

//
//  Preferences.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/17.
//

import Foundation
import Combine

private let homeUrlKey = "homeUrl"
private let customUrlKey = "customUrl"
private let didShowBluetoothParingDialogKey = "didShowBluetoothParingDialog"

class Preferences: ObservableObject {
    
    enum HomeUrl: String {
        case scratchHome
        case scratchEditor
        case scratchMyStuff
        case custom
        case documentsFolder
    }
    
    var homeUrl: HomeUrl {
        get {
            ManagedAppConfig.shared.rawRepresentable(forKey: homeUrlKey)
            ?? UserDefaults.standard.rawRepresentable(forKey: homeUrlKey)
            ?? .scratchEditor
        }
        set {
            UserDefaults.standard.setRawRepresentable(newValue, forKey: homeUrlKey)
        }
    }
    
    var customUrl: String {
        get {
            ManagedAppConfig.shared.string(forKey: customUrlKey)
            ?? UserDefaults.standard.string(forKey: customUrlKey)
            ?? "http://"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: customUrlKey)
        }
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
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.objectWillChange.send()
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

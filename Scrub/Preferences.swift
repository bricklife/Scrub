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
        case scratchEditor
        case scratchMyStuff
        case custom
        case documentsFolder
    }
    
    @Published var homeUrl: HomeUrl
    @Published var customUrl: String
    @Published var didShowBluetoothParingDialog: Bool
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        self.homeUrl = UserDefaults.standard.rawRepresentable(forKey: "homeUrl") ?? .scratchEditor
        self.customUrl = UserDefaults.standard.string(forKey: "customUrl") ?? "https://"
        self.didShowBluetoothParingDialog = UserDefaults.standard.bool(forKey: "didShowBluetoothParingDialog")
        
        $homeUrl.sink { (value) in
            UserDefaults.standard.setRawRepresentable(value, forKey: "homeUrl")
        }.store(in: &cancellables)
        $customUrl.sink { (value) in
            UserDefaults.standard.setValue(value, forKey: "customUrl")
        }.store(in: &cancellables)
        $didShowBluetoothParingDialog.sink { (value) in
            UserDefaults.standard.setValue(value, forKey: "didShowBluetoothParingDialog")
        }.store(in: &cancellables)
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

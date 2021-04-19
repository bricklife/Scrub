//
//  ScrubApp.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

@main
struct ScrubApp: App {
    
    @StateObject private var preferences = Preferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView(preferences: preferences)
        }
    }
}

//
//  ScrubApp.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

@main
struct ScrubApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var preferences = Preferences()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(preferences)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        LocalDocumentsManager.copyIndexHtmlIfNeeded()
        return true
    }
}

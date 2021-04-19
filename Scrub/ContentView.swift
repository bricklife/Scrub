//
//  ContentView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var preferences: Preferences
    
    init(preferences: Preferences) {
        self.preferences = preferences
    }
    
    var body: some View {
        WebView(url: preferences.initialUrl)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(preferences: Preferences())
    }
}

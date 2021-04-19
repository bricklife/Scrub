//
//  ContentView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var preferences: Preferences
    @StateObject private var webViewModel: WebViewModel
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self._webViewModel = StateObject(wrappedValue: WebViewModel(preferences: preferences))
    }
    
    var body: some View {
        WebView(viewModel: webViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(preferences: Preferences())
    }
}

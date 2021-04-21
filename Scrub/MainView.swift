//
//  MainView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject private var preferences: Preferences
    @StateObject private var webViewModel: WebViewModel
    
    @State private var isShowingPreferences = false
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self._webViewModel = StateObject(wrappedValue: WebViewModel(preferences: preferences))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: webViewModel)
                .sheet(isPresented: $isShowingPreferences) {
                    NavigationView {
                        PreferencesView(preferences: preferences)
                            .navigationTitle(Text("Preferences"))
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing){
                                    Button("Done") {
                                        isShowingPreferences = false
                                    }
                                }
                            }
                    }
                }
            VStack(spacing: 10) {
                Button(action: { webViewModel.apply(inputs: .goHome) }) {
                    Image(systemName: "house")
                }
                Button(action: { webViewModel.apply(inputs: .goBack) }) {
                    Image(systemName: "chevron.backward")
                }
                Button(action: { webViewModel.apply(inputs: .goForward) }) {
                    Image(systemName: "chevron.forward")
                }
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(preferences: Preferences())
    }
}

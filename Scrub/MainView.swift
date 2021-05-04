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
    @SceneStorage("lastUrl") private var lastUrl: URL?
    
    @State private var isShowingPreferences = false
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self._webViewModel = StateObject(wrappedValue: WebViewModel(preferences: preferences))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: webViewModel, lastUrl: $lastUrl)
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
                }.edgesIgnoringSafeArea([.bottom, .horizontal])
            VStack(spacing: 10) {
                Button(action: {
                    print(lastUrl ?? "nil")
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                ZStack {
                    CircleProgressView(progress: webViewModel.estimatedProgress)
                        .foregroundColor(.accentColor)
                        .opacity(webViewModel.isLoading ? 0.5 : 0.0)
                    if webViewModel.isLoading {
                        Button(action: { webViewModel.apply(inputs: .stopLoading) }) {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button(action: { webViewModel.apply(inputs: .reload) }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }.frame(width: 24, height: 24)
                Spacer()
                Button(action: { webViewModel.apply(inputs: .goHome) }) {
                    Image(systemName: "house")
                }
                Button(action: { webViewModel.apply(inputs: .goBack) }) {
                    Image(systemName: "chevron.backward")
                }.disabled(!webViewModel.canGoBack)
                Button(action: { webViewModel.apply(inputs: .goForward) }) {
                    Image(systemName: "chevron.forward")
                }.disabled(!webViewModel.canGoForward)
                Spacer()
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gear")
                }
            }.frame(width: 24).edgesIgnoringSafeArea([.horizontal])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(preferences: Preferences())
    }
}

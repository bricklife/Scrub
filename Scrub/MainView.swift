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
    @SceneStorage("lastUrl") private var url: URL?
    
    @State private var isShowingPreferences = false
    @State private var isShowingActivityView = false
    
    @State private var alertString: String? = nil
    private var isShowingAlert: Binding<Bool> {
        return Binding<Bool>(get: { alertString != nil }, set: { _ in alertString = nil })
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self._webViewModel = StateObject(wrappedValue: WebViewModel(preferences: preferences))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: webViewModel, url: $url, alertString: $alertString)
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
                .sheet(isPresented: $isShowingActivityView) {
                    if let url = url {
                        ActivityView(preferences: preferences, activityItems: [url])
                    }
                }
                .alert(isPresented: isShowingAlert) {
                    Alert(title: Text("Alert"), message: alertString.flatMap(Text.init))
                }
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            VStack(spacing: 8) {
                Button(action: {
                    isShowingActivityView = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(url?.scheme == "file")
                .opacity(url?.scheme == "file" ? 0.4 : 1.0)
                ZStack {
                    CircleProgressView(progress: webViewModel.estimatedProgress)
                        .opacity(webViewModel.isLoading ? 0.4 : 0.0)
                        .animation(.easeInOut(duration: 0.2))
                    if webViewModel.isLoading {
                        Button(action: { webViewModel.apply(inputs: .stopLoading) }) {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button(action: { webViewModel.apply(inputs: .reload) }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .frame(width: 24, height: 24)
                
                Spacer()
                
                Button(action: { webViewModel.apply(inputs: .goHome) }) {
                    Image(systemName: "house")
                }
                Button(action: { webViewModel.apply(inputs: .goBack) }) {
                    Image(systemName: "chevron.backward")
                }
                .opacity(webViewModel.canGoBack ? 1.0 : 0.4)
                Button(action: { webViewModel.apply(inputs: .goForward) }) {
                    Image(systemName: "chevron.forward")
                }
                .opacity(webViewModel.canGoForward ? 1.0 : 0.4)
                
                Spacer()
                
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gear")
                }
            }
            .padding(4)
            .edgesIgnoringSafeArea([.horizontal])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(preferences: Preferences())
    }
}

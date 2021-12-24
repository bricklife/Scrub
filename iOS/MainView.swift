//
//  MainView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject private var preferences: Preferences
    @StateObject private var alertController = AlertController()
    
    @StateObject private var webViewModel: WebViewModel
    @SceneStorage("lastUrl") private var url: URL?
    
    @State private var isShowingPreferences = false
    @State private var isShowingActivityView = false
    
    private var canShareUrl: Bool {
        guard let url = url else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self._webViewModel = StateObject(wrappedValue: WebViewModel(preferences: preferences))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: webViewModel, url: $url)
                .environmentObject(alertController)
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            VStack(spacing: 8) {
                Button(action: {
                    isShowingActivityView = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(!canShareUrl)
                .opacity(canShareUrl ? 1.0 : 0.4)
                
                ReloadAndStopButton(progress: webViewModel.estimatedProgress, isLoading: webViewModel.isLoading) {
                    if webViewModel.isLoading {
                        webViewModel.apply(inputs: .stopLoading)
                    } else {
                        webViewModel.apply(inputs: .reload)
                    }
                }
                
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
        .alert(isPresented: alertController.isShowingAlert) {
            alertController.makeAlert()
        }
    }
}

struct ReloadAndStopButton: View {
    
    let progress: Double
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            CircleProgressView(progress: progress)
                .opacity(isLoading ? 0.4 : 0.0)
                .animation(.easeInOut(duration: 0.2))
            Button(action: action) {
                if isLoading {
                    Image(systemName: "xmark")
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(preferences: Preferences())
    }
}

//
//  MainView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI
import SFUserFriendlySymbols

struct MainView: View {
    
    @EnvironmentObject private var preferences: Preferences
    @StateObject private var alertController = AlertController()
    
    @StateObject private var webViewModel = WebViewModel()
    @SceneStorage("lastUrl") private var lastUrl: URL?
    
    @State private var isShowingPreferences = false
    @State private var isShowingActivityView = false
    
    private var canShareUrl: Bool {
        guard let url = webViewModel.url else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: webViewModel)
                .environmentObject(alertController)
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            MenuBar()
                .padding(4)
                .edgesIgnoringSafeArea([.horizontal])
        }
        .sheet(isPresented: $isShowingPreferences) {
            NavigationView {
                PreferencesView()
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
            if let url = webViewModel.url {
                ActivityView(activityItems: [url])
            }
        }
        .alert(isPresented: alertController.isShowingAlert) {
            alertController.makeAlert()
        }
        .onAppear {
            try? webViewModel.initialLoad(lastUrl: lastUrl)
        }
        .onChange(of: webViewModel.url) { newValue in
            lastUrl = newValue
        }
    }
}

extension MainView {
    
    func MenuBar() -> some View {
        VStack(spacing: 8) {
            Button(action: {
                isShowingActivityView = true
            }) {
                Image(symbol: .squareAndArrowUp)
            }
            .disabled(!canShareUrl)
            .opacity(canShareUrl ? 1.0 : 0.4)
            
            ReloadAndStopButton(progress: webViewModel.estimatedProgress, isLoading: webViewModel.isLoading) {
                if webViewModel.isLoading {
                    webViewModel.stopLoading()
                } else {
                    webViewModel.reload()
                }
            }
            
            Spacer()
            
            Button(action: {
                do {
                    try webViewModel.goHome()
                } catch {
                    alertController.showAlert(error: error)
                }
            }) {
                Image(symbol: .house)
            }
            Button(action: { webViewModel.goBack() }) {
                Image(symbol: .chevronBackward)
            }
            .opacity(webViewModel.canGoBack ? 1.0 : 0.4)
            Button(action: { webViewModel.goForward() }) {
                Image(symbol: .chevronForward)
            }
            .opacity(webViewModel.canGoForward ? 1.0 : 0.4)
            
            Spacer()
            
            Button(action: { isShowingPreferences = true }) {
                Image(symbol: .gear)
            }
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
                    Image(symbol: .xmark)
                } else {
                    Image(symbol: .arrowClockwise)
                }
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(Preferences())
    }
}

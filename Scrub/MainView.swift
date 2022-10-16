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
    
    @SceneStorage("lastUrl") private var lastUrl: URL?
    
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var alertController = AlertController()
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: viewModel.webViewModel)
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            MenuBar(viewModel: viewModel)
                .padding(4)
                .edgesIgnoringSafeArea([.horizontal])
        }
        .environmentObject(alertController)
        .sheet(isPresented: $viewModel.isShowingPreferences) {
            NavigationView {
                PreferencesView()
                    .navigationTitle(Text("Preferences"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                viewModel.isShowingPreferences = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $viewModel.isShowingActivityView) {
            if let url = viewModel.webViewModel.url {
                ActivityView(activityItems: [url])
            }
        }
        .alert(isPresented: alertController.isShowingAlert) {
            alertController.makeAlert()
        }
        .onAppear {
            viewModel.set(preferences: preferences)
            try? viewModel.initialLoad(lastUrl: lastUrl)
        }
        .onChange(of: viewModel.webViewModel.url) { newValue in
            if let url = newValue {
                lastUrl = url
            }
        }
    }
}

struct MenuBar: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    @EnvironmentObject private var alertController: AlertController
    
    var body: some View {
        VStack(spacing: 8) {
            let canShareUrl = viewModel.webViewModel.url?.isHTTPsURL == true
            
            Button {
                viewModel.isShowingActivityView = true
            } label: {
                Image(symbol: .squareAndArrowUp)
            }
            .disabled(!canShareUrl)
            .opacity(canShareUrl ? 1.0 : 0.4)
            
            ReloadAndStopButton(progress: viewModel.webViewModel.estimatedProgress, isLoading: viewModel.webViewModel.isLoading) {
                if viewModel.webViewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            
            Spacer()
            
            Button {
                do {
                    try viewModel.goHome()
                } catch {
                    alertController.showAlert(error: error)
                }
            } label: {
                Image(symbol: .house)
            }
            Button {
                viewModel.goBack()
            } label: {
                Image(symbol: .chevronBackward)
            }
            .opacity(viewModel.webViewModel.canGoBack ? 1.0 : 0.4)
            Button {
                viewModel.goForward()
            } label: {
                Image(symbol: .chevronForward)
            }
            .opacity(viewModel.webViewModel.canGoForward ? 1.0 : 0.4)
            
            Spacer()
            
            Button {
                viewModel.isShowingPreferences = true
            } label: {
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

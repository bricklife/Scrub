//
//  MainView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/15.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var preferences: Preferences
    
    @SceneStorage("lastUrl") private var lastUrl: URL?
    
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var alertController = AlertController()
    
    @State private var eventTask: Task<(), Never>?
    
    var body: some View {
        HStack(spacing: 0) {
#if os(visionOS)
            VStack(spacing: 0) {
                OrnamentToolBar(viewModel: viewModel, alertController: alertController)
                    .frame(maxWidth: 800)
                    .frame(depth: 16)
                    .padding([.horizontal, .bottom], 24)
                
                WebView(viewModel: viewModel.webViewModel)
                    .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                    .glassBackgroundEffect(
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
#else
            WebView(viewModel: viewModel.webViewModel)
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            
            MainToolBar(viewModel: viewModel, alertController: alertController)
                .padding(4)
                .edgesIgnoringSafeArea([.horizontal])
#endif
        }
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
            if let url = viewModel.url {
                ActivityView(activityItems: [url])
            }
        }
        .alert(isPresented: alertController.isShowingAlert) {
            alertController.makeAlert()
        }
        .onAppear {
            viewModel.set(preferences: preferences)
            
            eventTask = Task {
                for await event in viewModel.eventChannel {
                    switch event {
                    case .error(let error):
                        alertController.showAlert(error: error)
                    case .forbiddenAccess(let url):
                        alertController.showAlert(forbiddenAccess: Text("This app can only open the official Scratch website or any Scratch Editor."), url: url)
                    case .openingBluetoothSession:
                        if !preferences.didShowBluetoothParingDialog {
                            alertController.showAlert(howTo: Text("Please pair your Bluetooth device on Settings app before using this extension.")) {
                                preferences.didShowBluetoothParingDialog = true
                            }
                        }
                    case .notSupportedExtension:
                        alertController.showAlert(sorry: Text("This extension is not supported🙇🏻"))
                    case .unauthorizedBluetooth:
                        alertController.showAlert(unauthorized: Text("Bluetooth"))
                    }
                }
            }
            
            try? viewModel.initialLoad(lastUrl: lastUrl)
        }
        .onDisappear {
            eventTask?.cancel()
        }
#if os(visionOS)
        .onChange(of: viewModel.url) { _, newValue in
            if let url = newValue {
                lastUrl = url
            }
        }
#else
        .onChange(of: viewModel.url) { newValue in
            if let url = newValue {
                lastUrl = url
            }
        }
#endif
        .onOpenURL { url in
            switch CustomUrlScheme(url: url) {
            case .openUrl(let openingUrl):
                viewModel.load(url: openingUrl)
            case .none:
                break
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(Preferences())
    }
}

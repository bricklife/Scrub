//
//  MainToolBar.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/16.
//

import SwiftUI
import SFUserFriendlySymbols

struct MainToolBar: View {
    
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var alertController: AlertController
    
    var body: some View {
        VStack(spacing: 8) {
            let canShareUrl = viewModel.url?.isHTTPsURL == true
            
            // Share
            Button {
                viewModel.isShowingActivityView = true
            } label: {
                Image(symbol: .squareAndArrowUp)
            }
            .menuButtonStyle(enabled: canShareUrl)
            
            // Reload and Stop
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            .menuButtonStyle()
            
            Spacer()
            
            // Home
            Button {
                do {
                    try viewModel.goHome()
                } catch {
                    alertController.showAlert(error: error)
                }
            } label: {
                Image(symbol: .house)
            }
            .menuButtonStyle()
            
            // Back
            Button {
                viewModel.goBack()
            } label: {
                Image(symbol: .chevronBackward)
            }
            .menuButtonStyle(enabled: viewModel.canGoBack)
            
            // Forward
            Button {
                viewModel.goForward()
            } label: {
                Image(symbol: .chevronForward)
            }
            .menuButtonStyle(enabled: viewModel.canGoForward)
            
            Spacer()
            
            // Settings
            Button {
                viewModel.isShowingPreferences = true
            } label: {
                Image(symbol: .gear)
            }
            .menuButtonStyle()
        }
    }
}

private extension View {
    
    func menuButtonStyle(enabled: Bool = true) -> some View {
        self
            .frame(width: 24, height: 24)
            .hoverEffect()
            .disabled(!enabled)
    }
}

struct MainToolBar_Previews: PreviewProvider {
    static var previews: some View {
        MainToolBar(viewModel: MainViewModel(), alertController: AlertController())
    }
}

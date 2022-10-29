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
            
            MenuButton("Share", symbol: .squareAndArrowUp) {
                viewModel.isShowingActivityView = true
            }
            .enabled(canShareUrl)
            
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            
            Spacer()
            
            MenuButton("Home", symbol: .house) {
                do {
                    try viewModel.goHome()
                } catch {
                    alertController.showAlert(error: error)
                }
            }
            .keyboardShortcut("H", modifiers: [.command, .shift])
            
            
            MenuButton("Back", symbol: .chevronBackward) {
                viewModel.goBack()
            }
            .enabled(viewModel.canGoBack)
            .keyboardShortcut("[")
            
            MenuButton("Forward", symbol: .chevronForward) {
                viewModel.goForward()
            }
            .enabled(viewModel.canGoForward)
            .keyboardShortcut("]")
            
            Spacer()
            
            // Preferences
            MenuButton("Preferences", symbol: .gear) {
                viewModel.isShowingPreferences = true
            }
            .keyboardShortcut(",")
        }
    }
}

private extension View {
    
    @ViewBuilder
    func enabled(_ enabled: Bool = true) -> some View {
        if #available(iOS 15.0, *) {
            self
                .disabled(!enabled)
        } else {
            self
                .opacity(enabled ? 1.0 : 0.4)
        }
    }
}

struct MainToolBar_Previews: PreviewProvider {
    static var previews: some View {
        MainToolBar(viewModel: MainViewModel(), alertController: AlertController())
    }
}

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
            .frame(width: 24, height: 24)
            .hoverEffect()
            .disabled(!canShareUrl)
            
            // Reload and Stop
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            .frame(width: 24, height: 24)
            .hoverEffect()
            
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
            .frame(width: 24, height: 24)
            .hoverEffect()
            
            // Back
            Button {
                viewModel.goBack()
            } label: {
                Image(symbol: .chevronBackward)
            }
            .frame(width: 24, height: 24)
            .hoverEffect()
            .disabled(!viewModel.canGoBack)
            
            // Forward
            Button {
                viewModel.goForward()
            } label: {
                Image(symbol: .chevronForward)
            }
            .frame(width: 24, height: 24)
            .hoverEffect()
            .disabled(!viewModel.canGoForward)
            
            Spacer()
            
            // Settings
            Button {
                viewModel.isShowingPreferences = true
            } label: {
                Image(symbol: .gear)
            }
            .frame(width: 24, height: 24)
            .hoverEffect()
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
    }
}

struct MainToolBar_Previews: PreviewProvider {
    static var previews: some View {
        MainToolBar(viewModel: MainViewModel(), alertController: AlertController())
    }
}

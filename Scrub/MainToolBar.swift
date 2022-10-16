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
            
            Button {
                viewModel.isShowingActivityView = true
            } label: {
                Image(symbol: .squareAndArrowUp)
            }
            .disabled(!canShareUrl)
            .opacity(canShareUrl ? 1.0 : 0.4)
            
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
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
            .opacity(viewModel.canGoBack ? 1.0 : 0.4)
            Button {
                viewModel.goForward()
            } label: {
                Image(symbol: .chevronForward)
            }
            .opacity(viewModel.canGoForward ? 1.0 : 0.4)
            
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

struct MainToolBar_Previews: PreviewProvider {
    static var previews: some View {
        MainToolBar(viewModel: MainViewModel(), alertController: AlertController())
    }
}

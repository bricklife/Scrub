//
//  OrnamentToolBar.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2024/02/09.
//

#if os(visionOS)
import SwiftUI
import SFUserFriendlySymbols

struct OrnamentToolBar: View {
    
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var alertController: AlertController
    
    var body: some View {
        HStack(spacing: 16) {
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
            
            MenuButton("Home", symbol: .house) {
                do {
                    try viewModel.goHome()
                } catch {
                    alertController.showAlert(error: error)
                }
            }
            .keyboardShortcut("H", modifiers: [.command, .shift])
            
            Text(viewModel.url?.absoluteString ?? "")
                .lineLimit(1)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity)
            
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            
            let canShareUrl = viewModel.url?.isHTTPsURL == true
            MenuButton("Share", symbol: .squareAndArrowUp) {
                viewModel.isShowingActivityView = true
            }
            .enabled(canShareUrl)
            
            // Preferences
            MenuButton("Preferences", symbol: .gear) {
                viewModel.isShowingPreferences = true
            }
            .keyboardShortcut(",")
        }
        .padding(10)
        .fixedSize(horizontal: false, vertical: true)
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 32)
        )
    }
}


private extension View {
    @ViewBuilder
    func enabled(_ enabled: Bool = true) -> some View {
        disabled(!enabled)
    }
}

#Preview {
    OrnamentToolBar(viewModel: MainViewModel(), alertController: AlertController())
}
#endif

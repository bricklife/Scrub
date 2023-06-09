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
    
    @State private var urlString = ""
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            let canShareUrl = viewModel.url?.isHTTPsURL == true
            
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
            
            TextField("URL", text: $urlString, onCommit: {
                if let url = URL(string: urlString) {
                    viewModel.load(url: url)
                    focused = false
                }
            })
            .keyboardType(.URL)
            .submitLabel(.go)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 12))
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(.primary.opacity(0.1))
            .cornerRadius(8)
            .focused($focused)
            
            ReloadAndStopButton(progress: viewModel.estimatedProgress, isLoading: viewModel.isLoading) {
                if viewModel.isLoading {
                    viewModel.stopLoading()
                } else {
                    viewModel.reload()
                }
            }
            
            MenuButton("Share", symbol: .squareAndArrowUp) {
                viewModel.isShowingActivityView = true
            }
            .enabled(canShareUrl)
        }
        .onChange(of: viewModel.url) { newValue in
            if let string = newValue?.absoluteString {
                urlString = string
            }
        }
    }
}

private extension View {
    
    @ViewBuilder
    func enabled(_ enabled: Bool = true) -> some View {
        self
            .disabled(!enabled)
    }
}

struct MainToolBar_Previews: PreviewProvider {
    static var previews: some View {
        MainToolBar(viewModel: MainViewModel(), alertController: AlertController())
    }
}

//
//  ReloadAndStopButton.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/25.
//

import SwiftUI

struct ReloadAndStopButton: View {
    
    let progress: Double
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            CircleProgressView(progress: progress)
                .opacity(isLoading ? 0.4 : 0.0)
                .animation(.easeInOut(duration: 0.2))
                .menuButtonStyle()
            if isLoading {
                MenuButton("Stop", symbol: .xmark, action: action)
                    .keyboardShortcut(".")
            } else {
                MenuButton("Reload", symbol: .arrowClockwise, action: action)
                    .keyboardShortcut("R")
            }
        }
    }
}

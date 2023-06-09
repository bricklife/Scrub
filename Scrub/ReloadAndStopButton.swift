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
                .frame(width: MenuButton.Size.small.length, height: MenuButton.Size.small.length)
                .opacity(isLoading ? 0.4 : 0.0)
                .animation(.easeInOut(duration: 0.2))
            if isLoading {
                MenuButton("Stop", symbol: .xmark, size: .small, action: action)
                    .keyboardShortcut(".")
            } else {
                MenuButton("Reload Page", symbol: .arrowClockwise, size: .small, action: action)
                    .keyboardShortcut("R")
            }
        }
    }
}

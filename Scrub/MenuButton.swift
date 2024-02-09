//
//  MenuButton.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/27.
//

import SwiftUI
import SFUserFriendlySymbols

struct MenuButton: View {
    let titleKey: LocalizedStringKey
    let symbol: SFSymbols
    let action: () -> Void
    
    init(_ titleKey: LocalizedStringKey, symbol: SFSymbols, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.symbol = symbol
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            // https://stackoverflow.com/a/70939660
            ZStack {
                Text(titleKey)
                    .frame(width: 0, height: 0)
                Image(symbol: symbol)
            }
        }
        .menuButtonStyle()
    }
}

extension View {
    
    @ViewBuilder
    func menuButtonStyle() -> some View {
#if os(visionOS)
        frame(width: 44, height: 44)
#else
        if #available(iOS 15.0, *) {
            self
                .frame(width: 24, height: 24)
                .hoverEffect()
        } else {
            self
                .frame(width: 24, height: 24)
        }
#endif
    }
}


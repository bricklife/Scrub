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
    let size: Size
    let action: () -> Void
    
    init(_ titleKey: LocalizedStringKey, symbol: SFSymbols, size: Size = .normal, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.symbol = symbol
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            // https://stackoverflow.com/a/70939660
            ZStack {
                Text(titleKey)
                    .frame(width: 0, height: 0)
                Image(symbol: symbol)
                    .font(.system(size: size.fontSize))
            }
        }
        .frame(width: size.length, height: size.length)
        .hoverEffect()
    }
}

extension MenuButton {
    
    enum Size {
        case normal
        case small
        
        var length: CGFloat {
            return 24
        }
        
        var fontSize: CGFloat {
            switch self {
            case .normal:
                return 18
            case .small:
                return 14
            }
        }
    }
}

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
    let shape: Shape
    let action: () -> Void
    
    init(_ titleKey: LocalizedStringKey, symbol: SFSymbols, shape: Shape = .square, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.symbol = symbol
        self.shape = shape
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            // https://stackoverflow.com/a/70939660
            ZStack {
                Text(titleKey)
                    .frame(width: 0, height: 0)
                Image(symbol: symbol)
                    .font(.system(size: shape.fontSize))
            }
        }
        .frame(for: shape)
        .hoverEffect()
    }
}

extension MenuButton {
    
    enum Shape {
        case square
        case circle
        
        var length: CGFloat {
            return 24
        }
        
        var fontSize: CGFloat {
            switch self {
            case .square:
                return 18
            case .circle:
                return 14
            }
        }
    }
}

extension View {
    
    @ViewBuilder
    func frame(for shape: MenuButton.Shape) -> some View {
        self.frame(width: shape.length, height: shape.length)
    }
}

//
//  CircleProgressView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/23.
//

import SwiftUI

struct CircleProgressView: View {
    
    let progress: Double
    
    var body: some View {
        Circle()
            .inset(by: 1.5)
            .trim(from: 0.0, to: CGFloat(progress))
            .stroke(Color.accentColor, lineWidth: 1.0)
            .rotationEffect(Angle(degrees: -90))
    }
}

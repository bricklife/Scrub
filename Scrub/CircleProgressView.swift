//
//  CircleProgressView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/23.
//

import SwiftUI

struct CircleProgressView : Shape {
    
    let progress: Double
    
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 - 1
        
        var p = Path()
        
        p.addArc(center: CGPoint(x: rect.midX, y:rect.midY),
                 radius: r,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(360 * progress - 90),
                 clockwise: false)
        
        return p.strokedPath(.init(lineWidth: 1))
    }
}

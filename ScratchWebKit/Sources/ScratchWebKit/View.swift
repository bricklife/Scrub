//
//  View.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/25.
//

#if canImport(UIKit)
import UIKit
public typealias View = UIView
#elseif canImport(AppKit)
import AppKit
public typealias View = NSView

extension NSView {
    var isUserInteractionEnabled: Bool {
        get {
            return true
        }
        set {
        }
    }
    
    var alpha: CGFloat {
        get {
            return alphaValue
        }
        set {
            alphaValue = newValue
        }
    }
}
#endif

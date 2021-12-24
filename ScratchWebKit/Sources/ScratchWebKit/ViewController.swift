//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/24.
//

#if canImport(UIKit)
import UIKit
public typealias ViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias ViewController = NSViewController
#endif

//
//  JavaScriptLoader.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/31.
//

import Foundation

class JavaScriptLoader {
    
    static func load(filename: String) -> String {
        guard let filepath = Bundle.module.path(forResource: filename, ofType: "js") else { return "" }
        guard let string = try? String(contentsOfFile: filepath) else { return "" }
        return string
    }
}

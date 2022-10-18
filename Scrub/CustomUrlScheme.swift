//
//  CustomUrlScheme.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/18.
//

import Foundation

enum CustomUrlScheme {
    case openUrl(URL)
}

extension CustomUrlScheme {
    
    init?(url: URL) {
        guard url.scheme == "scrub" else { return nil }
        switch url.host {
        case "open":
            guard let openingUrl = url.query.flatMap(URL.init(string:)) else { return nil }
            self = .openUrl(openingUrl)
        default:
            return nil
        }
    }
}

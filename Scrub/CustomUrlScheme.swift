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
        case "openUrl":
            let urlString = [url.query, url.fragment].compactMap({ $0 }).joined(separator: "#")
            guard let openingUrl = URL(string: urlString) else { return nil }
            self = .openUrl(openingUrl)
            
        default:
            return nil
        }
    }
}

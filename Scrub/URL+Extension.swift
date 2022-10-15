//
//  URL+Extension.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/15.
//

import Foundation

extension URL {
    
    var isScratchSite: Bool {
        let normalizedHost = "." + (host ?? "")
        let scratchHosts = [
            ".scratch.mit.edu",
            ".scratch-wiki.info",
            ".scratchfoundation.org",
            ".scratchjr.org",
        ]
        return scratchHosts.contains(where: normalizedHost.hasSuffix(_:))
    }
    
    var canShare: Bool {
        return scheme == "http" || scheme == "https"
    }
}

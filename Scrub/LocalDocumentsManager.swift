//
//  LocalDocumentsManager.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/21.
//

import Foundation

final class LocalDocumentsManager {
    
    static let indexHtmlUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("index.html")
    
    static func copyIndexHtmlIfNeeded() {
        guard !FileManager.default.fileExists(atPath: indexHtmlUrl.path) else { return }
        guard let originalUrl = Bundle.main.url(forResource: "index", withExtension: "html") else { return }
        do {
            try FileManager.default.copyItem(at: originalUrl, to: indexHtmlUrl)
        } catch {
            print(error)
        }
    }
}

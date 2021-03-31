//
//  BlobDownloader.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/31.
//

import Foundation
import WebKit

class BlobDownloader: NSObject {
    
    private struct Message: Codable {
        let filename: String
        let dataUri: URL
    }
    
    weak var webView: WKWebView?
    var downloadCompletion: ((URL) -> Void)?
    
    func setup(configuration: WKWebViewConfiguration) {
        configuration.userContentController.add(self, name: "download")
    }
    
    func downloadBlob() {
        let js = JavaScriptLoader.load(filename: "download-blob")
        webView?.evaluateJavaScript(js)
    }
}

extension BlobDownloader: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let jsonString = message.body as? String else { return }
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        guard let message = try? JSONDecoder().decode(Message.self, from: jsonData) else { return }
        
        guard let data = try? Data(contentsOf: message.dataUri) else { return }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(message.filename)
        guard FileManager.default.createFile(atPath: url.path, contents: data) else { return }
        print("Saved \(data.count) bytes at", url.path)
        
        downloadCompletion?(url)
    }
}

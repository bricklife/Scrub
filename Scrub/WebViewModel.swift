//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine
import ScratchWebKit

enum WebViewError: Error {
    case invalidUrl
}

extension WebViewError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("Invalid URL", comment: "Invalid URL")
        }
    }
}

class WebViewModel: ObservableObject {
    
    @Published var url: URL? = nil
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    private weak var webViewController: ScratchWebViewController!
    private var preferences: Preferences!
    
    private var didInitialLoad = false
    
    var home: URL? {
        switch preferences.home {
        case .scratchHome:
            return URL(string: "https://scratch.mit.edu/")
        case .scratchEditor:
            return URL(string: "https://scratch.mit.edu/projects/editor/")
        case .scratchMyStuff:
            return URL(string: "https://scratch.mit.edu/mystuff/")
        case .customUrl:
            if let url = URL(string: preferences.customUrl), url.scheme == "http" || url.scheme == "https" {
                return url
            }
            return nil
        case .documentsFolder:
            return LocalDocumentsManager.indexHtmlUrl
        }
    }
    
    func setup(webViewController: ScratchWebViewController, preferences: Preferences) {
        webViewController.$url.assign(to: &$url)
        webViewController.$isLoading.assign(to: &$isLoading)
        webViewController.$estimatedProgress.assign(to: &$estimatedProgress)
        webViewController.$canGoBack.assign(to: &$canGoBack)
        webViewController.$canGoForward.assign(to: &$canGoForward)
        
        self.webViewController = webViewController
        self.preferences = preferences
    }
    
    func initialLoad(lastUrl: URL?) throws {
        if didInitialLoad == false {
            didInitialLoad = true
            if let lastUrl = lastUrl, lastUrl.scheme != "file" {
                load(url: lastUrl)
            } else if let url = home {
                load(url: url)
            } else {
                throw WebViewError.invalidUrl
            }
        }
    }
    
    func goHome() throws {
        guard let url = home else {
            throw WebViewError.invalidUrl
        }
        webViewController.load(url: url)
    }
    
    func goBack() {
        webViewController.goBack()
    }
    
    func goForward() {
        webViewController.goForward()
    }
    
    func load(url: URL) {
        webViewController.load(url: url)
    }
    
    func reload() {
        webViewController.reload()
    }
    
    func stopLoading() {
        webViewController.stopLoading()
    }
}

//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine

class WebViewModel: ObservableObject {
    
    enum Inputs {
        case goHome
        case goBack
        case goForward
        case load(url: URL)
        case reload
        case stopLoading
    }
    
    let inputs: AnyPublisher<Inputs, Never>
    
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    private let preferences: Preferences
    private let inputsSubject: PassthroughSubject<Inputs, Never>
    
    init(preferences: Preferences) {
        self.preferences = preferences
        
        self.inputsSubject = PassthroughSubject<Inputs, Never>()
        self.inputs = inputsSubject.eraseToAnyPublisher()
    }
    
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
    
    func apply(inputs: Inputs) {
        inputsSubject.send(inputs)
    }
    
    func canAccess(url: URL) -> Bool {
#if DEBUG
        return true
#else
        return url.isScratchSite || url.isFileURL
#endif
    }
}

extension WebViewModel {
    
    var shouldShowBluetoothParingDialog: Bool {
        return !preferences.didShowBluetoothParingDialog
    }
    
    func didShowBluetoothParingDialog() {
        preferences.didShowBluetoothParingDialog = true
    }
}

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
}

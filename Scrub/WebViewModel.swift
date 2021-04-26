//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine

private let ScratchHomeUrl = URL(string: "https://scratch.mit.edu/projects/editor/")!

private func getHomeUrl(from preferences: Preferences) -> URL {
    switch preferences.homeUrl {
    case .scratchHome:
        return ScratchHomeUrl
    case .custom:
        return URL(string: preferences.customUrl) ?? ScratchHomeUrl
    case .documentsFolder:
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("index.html")
    }
}

class WebViewModel: ObservableObject {
    
    enum Inputs {
        case goHome
        case goBack
        case goForward
        case load(url: URL)
        case reload
        case stopLoading
    }
    
    let initialUrl: URL
    let inputs: AnyPublisher<Inputs, Never>
    
    @Published public var isLoading: Bool = false
    @Published public var estimatedProgress: Double = 0.0
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    
    private let preferences: Preferences
    private let inputsSubject: PassthroughSubject<Inputs, Never>
    
    init(preferences: Preferences) {
        self.preferences = preferences
        
        if preferences.launchingUrl == .lastUrl,
           let lastUrl = UserDefaults.standard.url(forKey: "lastUrl") {
            self.initialUrl = lastUrl
        } else {
            self.initialUrl = getHomeUrl(from: preferences)
        }
        
        self.inputsSubject = PassthroughSubject<Inputs, Never>()
        self.inputs = inputsSubject.eraseToAnyPublisher()
    }
    
    var homeUrl: URL {
        return getHomeUrl(from: preferences)
    }
    
    func updateLastUrl(_ url: URL?) {
        UserDefaults.standard.set(url, forKey: "lastUrl")
    }
    
    func apply(inputs: Inputs) {
        inputsSubject.send(inputs)
    }
}

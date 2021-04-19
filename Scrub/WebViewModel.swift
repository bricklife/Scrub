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
    
    let initialUrl: URL
    let requestedUrl: AnyPublisher<URL, Never>
    
    private let preferences: Preferences
    private let requestedUrlSubject: PassthroughSubject<URL, Never>
    
    enum Inputs {
        case goHome
        case load(url: URL)
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self.initialUrl = getHomeUrl(from: preferences)
        
        self.requestedUrlSubject = PassthroughSubject<URL, Never>()
        self.requestedUrl = requestedUrlSubject.eraseToAnyPublisher()
    }
    
    var homeUrl: URL {
        return getHomeUrl(from: preferences)
    }
    
    func apply(inputs: Inputs) {
        switch inputs {
        case .goHome:
            requestedUrlSubject.send(homeUrl)
        case .load(let url):
            requestedUrlSubject.send(url)
        }
    }
}

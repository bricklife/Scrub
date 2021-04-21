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
    }
    
    let initialUrl: URL
    let inputs: AnyPublisher<Inputs, Never>
    
    private let preferences: Preferences
    private let inputsSubject: PassthroughSubject<Inputs, Never>
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self.initialUrl = getHomeUrl(from: preferences)
        
        self.inputsSubject = PassthroughSubject<Inputs, Never>()
        self.inputs = inputsSubject.eraseToAnyPublisher()
    }
    
    var homeUrl: URL {
        return getHomeUrl(from: preferences)
    }
    
    func apply(inputs: Inputs) {
        inputsSubject.send(inputs)
    }
}

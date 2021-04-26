//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine

private let ScratchHomeUrl = URL(string: "https://scratch.mit.edu/projects/editor/")!

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
    
    var shoudUseLastUrl: Bool {
        return preferences.initialUrl == .lastUrl
    }
    
    var homeUrl: URL {
        switch preferences.homeUrl {
        case .scratchHome:
            return ScratchHomeUrl
        case .custom:
            return URL(string: preferences.customUrl) ?? ScratchHomeUrl
        case .documentsFolder:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("index.html")
        }
    }
    
    func apply(inputs: Inputs) {
        inputsSubject.send(inputs)
    }
}

//
//  MainViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/10/16.
//

import Foundation
import Combine

enum MainViewModelError: Error {
    case invalidUrl
}

extension MainViewModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("Invalid URL", comment: "Invalid URL")
        }
    }
}

@dynamicMemberLookup
@MainActor
class MainViewModel: ObservableObject {
    
    @Published var isShowingPreferences = false
    @Published var isShowingActivityView = false
    
    let webViewModel = WebViewModel()
    
    private var preferences: Preferences!
    
    private var didInitialLoad = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        webViewModel.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<WebViewModel, T>) -> T {
        webViewModel[keyPath: keyPath]
    }
    
    func set(preferences: Preferences) {
        self.preferences = preferences
    }
    
    var homeUrl: URL? {
        switch preferences.home {
        case .scratchHome:
            return URL(string: "https://scratch.mit.edu/")
        case .scratchEditor:
            return URL(string: "https://scratch.mit.edu/projects/editor/")
        case .scratchMyStuff:
            return URL(string: "https://scratch.mit.edu/mystuff/")
        case .customUrl:
            guard let url = URL(string: preferences.customUrl), url.isHTTPsURL else {
                return nil
            }
            return url
        case .documentsFolder:
            return LocalDocumentsManager.indexHtmlUrl
        }
    }
    
    func initialLoad(lastUrl: URL?) throws {
        if didInitialLoad == false {
            self.didInitialLoad = true
            if let lastUrl = lastUrl, !lastUrl.isFileURL {
                load(url: lastUrl)
            } else if let url = homeUrl {
                load(url: url)
            } else {
                throw MainViewModelError.invalidUrl
            }
        }
    }
    
    func goHome() throws {
        guard let url = homeUrl else {
            throw MainViewModelError.invalidUrl
        }
        webViewModel.apply(input: .load(url: url))
    }
    
    func load(url: URL) {
        webViewModel.apply(input: .load(url: url))
    }
    
    func goBack() {
        webViewModel.apply(input: .goBack)
    }
    
    func goForward() {
        webViewModel.apply(input: .goForward)
    }
    
    func reload() {
        webViewModel.apply(input: .reload)
    }
    
    func stopLoading() {
        webViewModel.apply(input: .stopLoading)
    }
}

//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine
import AsyncAlgorithms

@MainActor
class WebViewModel: ObservableObject {
    
    @Published var url: URL? = nil
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    let inputsChannel = AsyncChannel<Inputs>()
    
    deinit {
        inputsChannel.finish()
    }
    
    func apply(inputs: Inputs) {
        Task {
            await inputsChannel.send(inputs)
        }
    }
}

extension WebViewModel {
    
    enum Inputs {
        case load(url: URL)
        case goBack
        case goForward
        case reload
        case stopLoading
    }
}

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
    
    let inputChannel = AsyncChannel<Input>()
    
    deinit {
        inputChannel.finish()
    }
    
    func apply(input: Input) {
        Task {
            await inputChannel.send(input)
        }
    }
}

extension WebViewModel {
    
    enum Input {
        case load(url: URL)
        case goBack
        case goForward
        case reload
        case stopLoading
    }
}

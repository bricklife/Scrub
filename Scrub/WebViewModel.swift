//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine

class WebViewModel: ObservableObject {
    
    @Published var url: URL? = nil
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    private var continuation: AsyncStream<Inputs>.Continuation?
    
    var inputsStream: AsyncStream<Inputs> {
        AsyncStream<Inputs> { continuation in
            self.continuation = continuation
        }
    }
    
    func apply(inputs: Inputs) {
        continuation?.yield(inputs)
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

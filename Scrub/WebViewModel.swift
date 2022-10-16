//
//  WebViewModel.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/19.
//

import Foundation
import Combine
import ScratchWebKit

class WebViewModel: ObservableObject {
    
    @Published var url: URL? = nil
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    private weak var webViewController: ScratchWebViewController!
    
    func setup(webViewController: ScratchWebViewController) {
        webViewController.$url.assign(to: &$url)
        webViewController.$isLoading.assign(to: &$isLoading)
        webViewController.$estimatedProgress.assign(to: &$estimatedProgress)
        webViewController.$canGoBack.assign(to: &$canGoBack)
        webViewController.$canGoForward.assign(to: &$canGoForward)
        
        self.webViewController = webViewController
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

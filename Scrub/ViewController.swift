//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/03/20.
//

import UIKit
import Combine
import ScratchWebKit

class ViewController: UIViewController {
    
    private let webViewController = ScratchWebViewController()
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addWebViewController()
        
        webViewController.$isLoading.sink { (isLoading) in
            print("isLoading", isLoading)
        }.store(in: &cancellables)
        
        webViewController.load(url: URL(string: "https://scratch.mit.edu/projects/editor/")!)
    }
    
    private func addWebViewController() {
        addChild(webViewController)
        
        webViewController.view.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.frame = view.frame
        view.addSubview(webViewController.view)
        
        NSLayoutConstraint.activate([
            webViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            webViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        webViewController.didMove(toParent: self)
    }
}

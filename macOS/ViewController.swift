//
//  ViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/24.
//

import AppKit
import ScratchWebKit

class ViewController: NSViewController {
    
    @IBOutlet weak var webViewController: WebViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webViewController = children.first as? WebViewController
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        //let url = URL(string: "https://bricklife.com/scratch-gui/")!
        let url = URL(string: "https://stretch3.github.io/")!
        webViewController?.load(url: url)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}

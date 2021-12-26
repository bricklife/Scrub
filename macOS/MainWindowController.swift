//
//  MainWindowController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/27.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        shouldCascadeWindows = true
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
}

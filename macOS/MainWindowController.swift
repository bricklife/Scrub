//
//  MainWindowController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/26.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var backButton: NSToolbarItem!
    @IBOutlet weak var forwardButton: NSToolbarItem!
    @IBOutlet weak var reloadButton: NSToolbarItem!
    @IBOutlet weak var textField: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        backButton.autovalidates = false
        forwardButton.autovalidates = false
    }
}

//
//  MainToolbar.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/12/26.
//

import Cocoa

class MainToolbar: NSToolbar {
    
    @IBOutlet weak var backButton: NSToolbarItem!
    @IBOutlet weak var forwardButton: NSToolbarItem!
    @IBOutlet weak var reloadButton: NSToolbarItem!
    @IBOutlet weak var stopButton: NSToolbarItem!
    @IBOutlet weak var textField: NSTextField!
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                if let index = items.firstIndex(of: reloadButton) {
                    removeItem(at: index)
                    insertItem(withItemIdentifier: stopButton.itemIdentifier, at: index)
                }
            } else {
                if let index = items.firstIndex(of: stopButton) {
                    removeItem(at: index)
                    insertItem(withItemIdentifier: reloadButton.itemIdentifier, at: index)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backButton.autovalidates = false
        forwardButton.autovalidates = false
    }
}

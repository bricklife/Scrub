//
//  PreferencesViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2022/02/19.
//

import Cocoa

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var groupView: NSView!
    
    private var preferences: Preferences {
        return AppDelegate.shared.preferences
    }
    
    private let homeArray: [Preferences.Home] = [
        .scratchHome,
        .scratchEditor,
        .scratchMyStuff,
        .customUrl,
    ]
    
    private var buttons: [NSButton] {
        return groupView.subviews
            .compactMap({ $0 as? NSButton })
            .sorted(by: { $0.tag < $1.tag })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let home = preferences.home
        let index = homeArray.firstIndex(of: home) ?? 1
        buttons[index].state = .on
        
        textField.stringValue = preferences.customUrl
        textField.delegate = self
    }
    
    @IBAction func selectHome(_ sender: NSButton) {
        preferences.home = homeArray[sender.tag]
    }
}

extension PreferencesViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        preferences.customUrl = textField.stringValue
    }
}

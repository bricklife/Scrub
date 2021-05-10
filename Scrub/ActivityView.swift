//
//  ActivityView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/04.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    
    let preferences: Preferences
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: [HomeUrlActivity(preferences: preferences) ,SafariActivity()])
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

class HomeUrlActivity: UIActivity {
    
    let preferences: Preferences
    var url: URL? = nil
    
    init(preferences: Preferences) {
        self.preferences = preferences
        super.init()
    }
    
    override var activityTitle: String? {
        return "Set as Home URL"
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "house")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let _ = item as? URL {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                self.url = url
                break
            }
        }
    }
    
    override func perform() {
        if let url = url {
            preferences.homeUrl = .custom
            preferences.customUrl = url.absoluteString
        }
        activityDidFinish(true)
    }
}

class SafariActivity: UIActivity {
    
    var url: URL? = nil
    
    override var activityTitle: String? {
        return "Open in Web Browser"
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "safari")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                self.url = url
                break
            }
        }
    }
    
    override func perform() {
        if let url = url {
            UIApplication.shared.open(url)
        }
        activityDidFinish(true)
    }
}

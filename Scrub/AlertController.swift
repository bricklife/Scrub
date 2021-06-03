//
//  AlertController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/28.
//

import SwiftUI

class AlertController: ObservableObject {
    
    private struct Content {
        let title: Text
        let message: Text
        let completion: () -> Void
    }
    
    private var alertContent: Content? = nil {
        willSet {
            objectWillChange.send()
        }
    }
    
    var isShowingAlert: Binding<Bool> {
        return Binding<Bool>(get: { self.alertContent != nil }, set: { _ in self.alertContent = nil })
    }
    
    func showAlert(error: Error) {
        self.alertContent = Content(title: Text("Error"), message: Text(error.localizedDescription), completion: {})
    }
    
    func showAlert(howTo message: Text, completion: @escaping () -> Void = {}) {
        self.alertContent = Content(title: Text("How to Use"), message: message, completion: completion)
    }
    
    func showAlert(sorry message: Text) {
        self.alertContent = Content(title: Text("Sorry"), message: message, completion: {})
    }
    
    func makeAlert() -> Alert {
        return Alert(title: alertContent?.title ?? Text("Alert"),
                     message: alertContent?.message,
                     dismissButton: .default(Text("OK"), action: alertContent?.completion))
    }
}

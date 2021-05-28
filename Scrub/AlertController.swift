//
//  AlertController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/28.
//

import SwiftUI

class AlertController: ObservableObject {
    
    private var alertError: Error? = nil {
        willSet {
            objectWillChange.send()
        }
    }
    
    var isShowingAlert: Binding<Bool> {
        return Binding<Bool>(get: { self.alertError != nil }, set: { _ in self.alertError = nil })
    }
    
    func showAlert(error: Error) {
        self.alertError = error
    }

    func makeAlert() -> Alert {
        return Alert(title: Text("Alert"), message: alertError.flatMap { Text($0.localizedDescription) })
    }
}

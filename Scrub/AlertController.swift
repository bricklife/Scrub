//
//  AlertController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/28.
//

import SwiftUI

@MainActor
class AlertController: ObservableObject {
    
    @Environment(\.openURL) private var openURL
    
    private enum Content {
        case error(error: Error)
        case howTo(message: Text, completion: () -> Void)
        case sorry(message: Text)
        case forbiddenAccess(message: Text, url: URL)
        case unauthorized(type: Text)
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
        self.alertContent = .error(error: error)
    }
    
    func showAlert(howTo message: Text, completion: @escaping () -> Void = {}) {
        self.alertContent = .howTo(message: message, completion: completion)
    }
    
    func showAlert(sorry message: Text) {
        self.alertContent = .sorry(message: message)
    }
    
    func showAlert(forbiddenAccess message: Text, url: URL) {
        self.alertContent = .forbiddenAccess(message: message, url: url)
    }
    
    func showAlert(unauthorized type: Text) {
        self.alertContent = .unauthorized(type: type)
    }
    
    func makeAlert() -> Alert {
        switch alertContent {
        case let .error(error: error):
            return Alert(title: Text("Error"), message: Text(error.localizedDescription))
            
        case let .howTo(message: message, completion: completion):
            return Alert(title: Text("How to Use"), message: message,
                         dismissButton: .default(Text("OK"), action: completion))
            
        case let .sorry(message: message):
            return Alert(title: Text("Sorry"), message: message)
            
        case let .forbiddenAccess(message: message, url: url):
            return Alert(title: Text("Sorry"), message: message,
                         primaryButton: .default(Text("Open in Browser"), action: { [weak self] in
                            self?.openURL(url)
                         }),
                         secondaryButton: .default(Text("OK")))
            
        case let .unauthorized(type: type):
            let title = Text("\(type) is Not Allowed")
            let message = Text("Allow \(type) access in Settings to use this function.")
            let url = URL(string: UIApplication.openSettingsURLString)!
            return Alert(title: title, message: message,
                         primaryButton: .default(Text("Settings"), action: { [weak self] in
                            self?.openURL(url)
                         }),
                         secondaryButton: .default(Text("Close")))
            
        case .none:
            return Alert(title: Text("An unexpected error has occurred."))
        }
    }
}

//
//  PreferencesView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/18.
//

import SwiftUI

struct PreferencesView: View {
    
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section(header: Text("Home URL")) {
            Button(action: {
                preferences.homeUrl = .scratchHome
            }) {
                HStack {
                    Text("Scratch Home").foregroundColor(.black)
                    Spacer()
                    if preferences.homeUrl == .scratchHome {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                preferences.homeUrl = .custom
            }) {
                VStack {
                    HStack {
                        Text("Custom").foregroundColor(.black)
                        Spacer()
                        if preferences.homeUrl == .custom {
                            Image(systemName: "checkmark")
                        }
                    }
                    TextField("https://", text: $preferences.customUrl)
                }
            }
            Button(action: {
                preferences.homeUrl = .documentsFolder
            }) {
                HStack {
                    Text("Local Documents Folder").foregroundColor(.black)
                    Spacer()
                    if preferences.homeUrl == .documentsFolder {
                        Image(systemName: "checkmark")
                    }
                }
            }
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(preferences: Preferences())
    }
}

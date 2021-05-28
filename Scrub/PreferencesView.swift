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
                    closeKeyboard()
                    preferences.homeUrl = .scratchHome
                }) {
                    HStack {
                        Text("Scratch Home").foregroundColor(.primary)
                        Spacer()
                        if preferences.homeUrl == .scratchHome {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchEditor
                }) {
                    HStack {
                        Text("Scratch Editor (Create New Project)").foregroundColor(.primary)
                        Spacer()
                        if preferences.homeUrl == .scratchEditor {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchMyStuff
                }) {
                    HStack {
                        Text("Scratch My Stuff").foregroundColor(.primary)
                        Spacer()
                        if preferences.homeUrl == .scratchMyStuff {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .custom
                }) {
                    VStack {
                        HStack {
                            Text("Custom").foregroundColor(.primary)
                            Spacer()
                            if preferences.homeUrl == .custom {
                                Image(systemName: "checkmark")
                            }
                        }
                        TextField("https://", text: $preferences.customUrl, onCommit: {
                            preferences.homeUrl = .custom
                        })
                        .foregroundColor(.secondary)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .documentsFolder
                }) {
                    HStack {
                        Text("Local Documents Folder").foregroundColor(.primary)
                        Spacer()
                        if preferences.homeUrl == .documentsFolder {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Section {
                NavigationLink("Special Thanks", destination:
                                Form {
                                    Section(footer: Text("This implementation of Scratch Link function is inspired by toio Do app.")) {
                                        Link(destination: URL(string: "https://toio.io/special/do/")!) {
                                            HStack {
                                                Text("toio Do")
                                                Spacer()
                                                Image(systemName: "globe")
                                            }
                                        }
                                    }
                                    Section(footer: Text("\"toio\" is a trademark or registered trademark of Sony Interactive Entertainment Inc.")) {}
                                }
                                .navigationTitle(Text("Special Thanks"))
                )
            }
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionString())
                }
            }
            Section(footer: Text("Scratch is a project of the Scratch Foundation, in collaboration with the Lifelong Kindergarten Group at the MIT Media Lab. It is available for free at https://scratch.mit.edu.")) {}
        }
    }
    
    private func versionString() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(version) (\(build))"
        }
        return ""
    }
    
    private func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(preferences: Preferences())
    }
}

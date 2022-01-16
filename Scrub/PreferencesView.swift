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
            // Home URL
            Section(header: HStack {
                Label("Home URL", systemImage: "house")
                if preferences.isHomeUrlLocked {
                    LockImage()
                }
            }.font(.headline)) {
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchHome
                }) {
                    CheckmarkText(title: Text("Scratch Home"), checked: preferences.homeUrl == .scratchHome)
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchEditor
                }) {
                    CheckmarkText(title: Text("Scratch Editor (Create New Project)"), checked: preferences.homeUrl == .scratchEditor)
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchMyStuff
                }) {
                    CheckmarkText(title: Text("Scratch My Stuff"), checked: preferences.homeUrl == .scratchMyStuff)
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .custom
                }) {
                    VStack {
                        CheckmarkText(title: Text("Custom"), checked: preferences.homeUrl == .custom)
                        URLTextField(text: $preferences.customUrl, disabled: preferences.isCustomUrlLocked, onEditingChanged: { isEditing in
                            if isEditing {
                                preferences.homeUrl = .custom
                            }
                        })
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .documentsFolder
                }) {
                    CheckmarkText(title: Text("Local Documents Folder"), checked: preferences.homeUrl == .documentsFolder)
                }
            }.disabled(preferences.isHomeUrlLocked)
            
            // Support, Special Thanks
            Section {
                NavigationLink("Support", destination:
                                Form {
                                    Section {
                                        WebLink(title: Text("GitHub"), destination: URL(string: "https://github.com/bricklife/Scrub")!)
                                        WebLink(title: Text("Twitter: @ooba"), destination: URL(string: "https://twitter.com/ooba")!)
                                    }
                                }
                                .navigationTitle(Text("Support"))
                )
                NavigationLink("Special Thanks", destination:
                                Form {
                                    Section(header: Text("This implementation of Scratch Link function is inspired by toio Do iPad app."),
                                            footer: Text("\"toio\" is a trademark or registered trademark of Sony Interactive Entertainment Inc.")) {
                                        WebLink(title: Text("toio Do"), destination: URL(string: "https://toio.io/special/do/")!)
                                    }
                                    .textCase(nil)
                                }
                                .navigationTitle(Text("Special Thanks"))
                )
            }
            
            // Version
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionString())
                }
            }
            
            // Footer
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

private struct LockImage: View {
    
    var body: some View {
        Image(systemName: "lock.fill").foregroundColor(.red)
    }
}

private struct CheckmarkText: View {
    
    let title: Text
    let checked: Bool
    
    var body: some View {
        HStack {
            title.foregroundColor(.primary)
            Spacer()
            if checked {
                Image(systemName: "checkmark")
            }
        }
    }
}

private struct URLTextField: View {
    
    @Binding var text: String
    let disabled: Bool
    let onEditingChanged: (Bool) -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            if disabled {
                LockImage()
            }
            
            TextField("https://", text: $text, onEditingChanged: { isEditing in
                self.isEditing = isEditing
                onEditingChanged(isEditing)
            })
                .foregroundColor(.secondary)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .disabled(disabled)
            
            if isEditing && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct WebLink: View {
    
    let title: Text
    let destination: URL
    
    var body: some View {
        Link(destination: destination) {
            HStack {
                title
                Spacer()
                Image(systemName: "globe")
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(preferences: Preferences())
    }
}

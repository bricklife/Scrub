//
//  PreferencesView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/18.
//

import SwiftUI

struct PreferencesView: View {
    
    @EnvironmentObject private var preferences: Preferences
    
    var body: some View {
        Form {
            // Home
            Section(header: HStack {
                Label("Home", systemImage: "house")
                if preferences.isHomeLocked {
                    LockImage()
                }
            }.font(.headline)) {
                Button {
                    closeKeyboard()
                    preferences.home = .scratchHome
                } label: {
                    CheckmarkText(title: Text("Scratch - Home"), checked: preferences.home == .scratchHome)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .scratchEditor
                } label: {
                    CheckmarkText(title: Text("Scratch - Editor (Create New Project)"), checked: preferences.home == .scratchEditor)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .scratchMyStuff
                } label: {
                    CheckmarkText(title: Text("Scratch - My Stuff"), checked: preferences.home == .scratchMyStuff)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .customUrl
                } label: {
                    VStack {
                        CheckmarkText(title: Text("Custom URL"), checked: preferences.home == .customUrl)
                        URLTextField(text: $preferences.customUrl, disabled: preferences.isCustomUrlLocked, onEditingChanged: { isEditing in
                            if isEditing {
                                preferences.home = .customUrl
                            }
                        })
                    }
                }
                Button {
                    closeKeyboard()
                    preferences.home = .documentsFolder
                } label: {
                    CheckmarkText(title: Text("Local Documents Folder"), checked: preferences.home == .documentsFolder)
                }
            }.disabled(preferences.isHomeLocked)
            
            // Support
            Section(header: HStack {
                Label("Support", systemImage: "message")
            }.font(.headline)) {
                WebLink(title: Text("GitHub"), destination: URL(string: "https://github.com/tfabworks/Scrub")!)
                WebLink(title: Text("Twitter: @TFabWorks"), destination: URL(string: "https://twitter.com/TFabWorks")!)
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
        Image(symbol: .lockFill).foregroundColor(.red)
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
                Image(symbol: .checkmark)
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
                Button {
                    text = ""
                } label: {
                    Image(symbol: .xmarkCircleFill)
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
                Image(symbol: .globe)
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Preferences())
    }
}

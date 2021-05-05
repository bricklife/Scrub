//
//  ActivityView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/05/04.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

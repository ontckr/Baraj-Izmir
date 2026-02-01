//
//  BarajizmirApp.swift
//  Barajizmir
//
//  Created by Onat Çakır on 31.01.2026.
//

import SwiftUI

@main
struct BarajizmirApp: App {
    init() {
        Task { @MainActor in
            ReviewManager.shared.incrementLaunchCount()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            BarrageListView()
        }
    }
}

//
//  ContentView.swift
//  Barajizmir
//
//  Created by Onat Çakır on 31.01.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        BarrageListView()
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}


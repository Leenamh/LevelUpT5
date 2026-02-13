//
//  ContentView.swift
//  Bashkah
//
//  Main navigation controller for all games
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SplashPageView()
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    ContentView()
}

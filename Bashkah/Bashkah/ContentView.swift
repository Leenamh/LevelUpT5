//
//  ContentView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 15/08/1447 AH.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        NavigationStack {
            TrendingTopicStartView()
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    ContentView()
}

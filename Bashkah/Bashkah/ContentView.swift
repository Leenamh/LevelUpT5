//
//  ContentView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 15/08/1447 AH.
//

import SwiftUI



struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomePageView(path: $path) // your homepage
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomePageView(path: $path)

                    case .trendingStart:
                        TrendingTopicStartView(path: $path)

                    case .trendingJoin(let name):
                        TrendingTopicJoinView(
                            vm: TrendingTopicJoinVM(displayName: name),
                            path: $path
                        )

                    case .trendingLobby(let room, let isHost):
                        TrendingTopicLobbyView(
                            path: $path,
                            vm: TrendingTopicLobbyVM(room: room, isHost: isHost)
                        )

                    case .trendingGame:
                        TrendingTopicGameView(
                            vm: TrendingTopicGameVM(),
                            path: $path
                        )
                    }
                }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}



#Preview {
    ContentView()
}

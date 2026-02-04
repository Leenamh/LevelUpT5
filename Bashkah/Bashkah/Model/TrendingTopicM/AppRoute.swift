//
//  AppRoute.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import Foundation

enum AppRoute: Hashable {
    case home

    // Trending Topic flow
    case trendingStart
    case trendingJoin(name: String)
    case trendingLobby(room: TTRoom, isHost: Bool)
    case trendingGame
}



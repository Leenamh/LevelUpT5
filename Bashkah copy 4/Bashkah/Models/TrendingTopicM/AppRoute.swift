//
//  AppRoute.swift
//  Bashkah
//
//  Complete routing for all three games
//

import Foundation

enum AppRoute: Hashable {
    // MARK: - Fun Fact Routes
    case funFactStart
    case funFactJoin
    case funFactWriting
    case funFactJoker
    case funFactOpinion
    case funFactVoting
    case funFactWinners
    
    // MARK: - Trending Topic Routes
    case trendingStart
    case trendingJoin
    case trendingLobby(room: TTRoom, isHost: Bool)
    case trendingGame
    
    // MARK: - Unpopular Opinion Routes
    case unpopularStart
    case unpopularJoin
    case unpopularWriting(roomCode: String, isHost: Bool)
    case unpopularLobby(room: UORoom, isHost: Bool)
    case unpopularVoting(room: UORoom, currentPlayerID: UUID)
    case unpopularResults(room: UORoom)
}

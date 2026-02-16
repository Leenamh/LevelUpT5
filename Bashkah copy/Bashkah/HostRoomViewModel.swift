//
//  HostRoomViewModel.swift
//  Bashkah
//
//  Migrated to Firebase - 14/02/2026
//

import Foundation
import SwiftUI

class HostRoomViewModel: ObservableObject {
    @Published var manager = FirebaseMultiplayerManager()
    @Published var roomNumber: String = ""
    @Published var isCreatingRoom: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Create Room
    func createRoom(gameType: GameType) {
        guard !roomNumber.isEmpty else {
            errorMessage = "الرجاء إدخال رقم الغرفة"
            return
        }
        
        isCreatingRoom = true
        
        // Host creates a room
        manager.hostRoom(roomNumber: roomNumber, gameType: gameType)
        
        // Setup callbacks
        setupCallbacks()
        
        isCreatingRoom = false
        print("🟢 Room created: \(roomNumber)")
    }
    
    // MARK: - Setup Callbacks
    private func setupCallbacks() {
        manager.onPlayerJoined = { [weak self] player in
            print("👋 New player: \(player.name)")
            // You can update UI or show notification here
        }
        
        manager.onPlayerLeft = { [weak self] player in
            print("👋 Player left: \(player.name)")
        }
        
        manager.onGameStateChanged = { [weak self] state in
            print("📊 Game state: \(state.status.rawValue)")
            print("Current round: \(state.currentRound)")
            print("Current turn: \(state.currentTurn)")
        }
        
        manager.onRoomUpdated = { [weak self] in
            print("🔄 Room updated")
        }
    }
    
    // MARK: - Start Game
    func startGame() {
        // Check if all players are ready
        let allReady = manager.connectedPlayers.allSatisfy { $0.isReady }
        
        guard allReady else {
            errorMessage = "ليس كل اللاعبين جاهزين"
            return
        }
        
        guard manager.connectedPlayers.count >= 2 else {
            errorMessage = "يجب أن يكون هناك لاعبان على الأقل"
            return
        }
        
        manager.startGame()
        print("🎮 Game started!")
    }
    
    // MARK: - Next Round
    func nextRound() {
        guard let currentRound = manager.currentRoom?.currentRound else { return }
        
        // Move to next round
        manager.updateGameState(currentRound: currentRound + 1)
        print("➡️ Moving to round \(currentRound + 1)")
    }
    
    // MARK: - Next Turn
    func nextTurn() {
        // Get next player in turn order
        let players = manager.connectedPlayers
        guard let currentTurn = manager.currentRoom?.currentTurn,
              let currentIndex = players.firstIndex(where: { $0.id == currentTurn }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % players.count
        let nextPlayerId = players[nextIndex].id
        
        manager.updateGameState(currentTurn: nextPlayerId)
        print("➡️ Next turn: \(players[nextIndex].name)")
    }
    
    // MARK: - End Game
    func endGame() {
        manager.endGame()
        print("🏁 Game ended!")
        // This will automatically:
        // 1. Set status to "finished"
        // 2. Update all players' totalGames, wins, and coins
    }
    
    // MARK: - Leave Room
    func leaveRoom() {
        manager.disconnect()
        roomNumber = ""
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    var canStartGame: Bool {
        let allReady = manager.connectedPlayers.allSatisfy { $0.isReady }
        let enoughPlayers = manager.connectedPlayers.count >= 2
        return allReady && enoughPlayers
    }
    
    var playerCount: Int {
        return manager.connectedPlayers.count
    }
    
    var readyPlayerCount: Int {
        return manager.connectedPlayers.filter { $0.isReady }.count
    }
}

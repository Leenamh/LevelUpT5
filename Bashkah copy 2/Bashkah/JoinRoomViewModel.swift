//
//  JoinRoomViewModel.swift
//  Bashkah
//
//  Migrated to Firebase - 14/02/2026
//

import Foundation
import SwiftUI

class JoinRoomViewModel: ObservableObject {
    @Published var manager = FirebaseMultiplayerManager()
    @Published var selectedRoom: GameRoom?
    @Published var isJoining: Bool = false
    @Published var errorMessage: String?

    // MARK: - Browse Rooms
    func browseRooms(for gameType: GameType) {
        manager.startBrowsing(for: gameType)
        setupCallbacks()
        print("🔍 Browsing for \(gameType.rawValue) rooms...")
    }

    // MARK: - Setup Callbacks
    private func setupCallbacks() {
        manager.onGameStateChanged = { state in
            switch state.status {
            case .waiting:
                print("⏳ Waiting for game to start...")
            case .playing:
                print("🎮 Game started! Round \(state.currentRound)")
            case .finished:
                print("🏁 Game finished!")
            }
        }

        manager.onPlayerJoined = { player in
            print("👋 Player joined: \(player.name)")
        }

        manager.onPlayerLeft = { player in
            print("👋 Player left: \(player.name)")
        }

        manager.onRoomUpdated = {
            print("🔄 Room updated")
        }
    }

    // MARK: - Join Room
    func joinRoom(_ room: GameRoom) {
        guard !isJoining else { return }

        isJoining = true
        selectedRoom = room

        // ✅ ensure browsing listeners stop when we actually join
        manager.stopBrowsing()
        manager.joinRoom(room)

        print("✅ Joining room: \(room.roomNumber)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isJoining = false
        }
    }

    // MARK: - Set Ready
    func setReady() {
        manager.setPlayerReady(true)
        print("✅ Player marked as ready")
    }

    // MARK: - Set Not Ready
    func setNotReady() {
        manager.setPlayerReady(false)
        print("⏸️ Player marked as not ready")
    }

    // MARK: - Leave Room
    func leaveRoom() {
        manager.disconnect()
        selectedRoom = nil
        errorMessage = nil
        print("🚪 Left room")
    }

    // MARK: - Stop Browsing
    func stopBrowsing() {
        manager.stopBrowsing()
        print("🛑 Stopped browsing")
    }

    // MARK: - Computed Properties
    var availableRooms: [GameRoom] { manager.availableRooms }

    var isInRoom: Bool { manager.currentRoom != nil }

    var currentPlayerIsReady: Bool {
        guard let playerId = UserDefaults.standard.string(forKey: "playerId"),
              let player = manager.connectedPlayers.first(where: { $0.id == playerId }) else {
            return false
        }
        return player.isReady
    }

    var allPlayersReady: Bool {
        manager.connectedPlayers.allSatisfy { $0.isReady }
    }
}

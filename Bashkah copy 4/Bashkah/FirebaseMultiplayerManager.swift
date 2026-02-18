//
//  FirebaseMultiplayerManager.swift
//  Bashkah
//
//  Created by Firebase Migration on 13/02/2026.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseMultiplayerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var connectedPlayers: [GamePlayer] = []
    @Published var availableRooms: [GameRoom] = []
    @Published var currentRoom: GameRoom?
    @Published var isHosting: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected

    // MARK: - Firebase Components
    let db = Firestore.firestore()

    // MARK: - Constants
    private let maxPlayers = 8

    // MARK: - Callbacks
    var onMessageReceived: ((GameMessage) -> Void)?
    var onPlayerJoined: ((GamePlayer) -> Void)?
    var onPlayerLeft: ((GamePlayer) -> Void)?
    var onRoomUpdated: (() -> Void)?
    var onGameStateChanged: ((GameState) -> Void)?

    // MARK: - Current Player Info
    var currentPlayerId: String
    var currentPlayerName: String

    private var roomListeners: [ListenerRegistration] = []
    private var playersListener: ListenerRegistration?
    private var roomListener: ListenerRegistration?

    // MARK: - Initialization
    init() {
        // ✅ FIX: Stable playerId that is saved once and reused forever
        if let existing = UserDefaults.standard.string(forKey: "playerId"), !existing.isEmpty {
            self.currentPlayerId = existing
        } else {
            let newId = UUID().uuidString
            self.currentPlayerId = newId
            UserDefaults.standard.set(newId, forKey: "playerId")
        }

        if let existingName = UserDefaults.standard.string(forKey: "playerName"), !existingName.isEmpty {
            self.currentPlayerName = existingName
        } else {
            self.currentPlayerName = "Player"
            UserDefaults.standard.set(self.currentPlayerName, forKey: "playerName")
        }
    }

    // MARK: - Refresh Local Player Info (if name changes later)
    private func refreshLocalPlayerInfo() {
        if let name = UserDefaults.standard.string(forKey: "playerName"), !name.isEmpty {
            currentPlayerName = name
        }
        if let pid = UserDefaults.standard.string(forKey: "playerId"), !pid.isEmpty {
            currentPlayerId = pid
        }
    }

    // MARK: - Update Player Online Status
    func updatePlayerOnlineStatus(isOnline: Bool) {
        refreshLocalPlayerInfo()

        // ✅ FIX: use setData(merge:) so doc existence doesn’t break update
        db.collection("players").document(currentPlayerId).setData([
            "isOnline": isOnline,
            "name": currentPlayerName,
            "lastSeen": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Error updating online status: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Host Room
    func hostRoom(roomNumber: String, gameType: GameType) {
        refreshLocalPlayerInfo()

        // ✅ FIX: stop browsing listeners if any (prevents duplicate snapshots)
        stopBrowsing()

        isHosting = true
        connectionStatus = .hosting

        let roomId = "\(gameType.rawValue)_\(roomNumber)"

        // ✅ Safe defaults (extra fields harmless to other games)
        let roomData: [String: Any] = [
            "hostId": currentPlayerId,
            "gameType": gameType.rawValue,
            "status": "waiting",
            "createdAt": FieldValue.serverTimestamp(),
            "currentRound": 1,
            "currentTurn": currentPlayerId,
            "currentTopicIndex": 0,

            // FunFact fields
            "currentPhase": "lobby",
            "factsShuffled": false,
            "currentFactIndex": 0,
            "jokerPlayerId": ""
        ]

        db.collection("gameRooms").document(roomId).setData(roomData, merge: true) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error creating room: \(error.localizedDescription)")
                self.connectionStatus = .disconnected
                self.isHosting = false
                return
            }

            print("🟢 Room created: \(roomNumber)")

            // ✅ Add host as first player
            self.addPlayerToRoom(roomId: roomId, isHost: true)

            // ✅ FIX: remove any existing listeners before attaching
            self.detachRoomListeners()
            self.listenToRoom(roomId: roomId)
            self.listenToRoomPlayers(roomId: roomId)

            // Online status
            self.updatePlayerOnlineStatus(isOnline: true)

            self.currentRoom = GameRoom(
                id: roomId,
                roomId: roomId,
                roomNumber: roomNumber,
                gameType: gameType,
                hostId: self.currentPlayerId,
                status: .waiting,
                currentRound: 1,
                currentTurn: self.currentPlayerId,
                currentTopicIndex: 0,
                playerCount: 1
            )
        }
    }

    // MARK: - Browse Rooms
    func startBrowsing(for gameType: GameType) {
        refreshLocalPlayerInfo()

        connectionStatus = .browsing

        // ✅ FIX: clear old browsing listeners to avoid stacking
        for listener in roomListeners { listener.remove() }
        roomListeners.removeAll()

        let query = db.collection("gameRooms")
            .whereField("gameType", isEqualTo: gameType.rawValue)
            .whereField("status", isEqualTo: "waiting")

        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error browsing rooms: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No rooms found")
                self.availableRooms = []
                return
            }

            let group = DispatchGroup()
            var rooms: [GameRoom] = []

            for doc in documents {
                let data = doc.data()
                let roomId = doc.documentID

                guard let hostId = data["hostId"] as? String,
                      let gameTypeStr = data["gameType"] as? String,
                      let gameType = GameType(rawValue: gameTypeStr),
                      let statusStr = data["status"] as? String,
                      let status = RoomStatus(rawValue: statusStr),
                      let currentRound = data["currentRound"] as? Int,
                      let currentTurn = data["currentTurn"] as? String,
                      let currentTopicIndex = data["currentTopicIndex"] as? Int else {
                    continue
                }

                let roomNumber = roomId.replacingOccurrences(of: "\(gameType.rawValue)_", with: "")

                group.enter()
                self.db.collection("gameRooms").document(roomId).collection("players").getDocuments { snapshot, _ in
                    defer { group.leave() }
                    let playerCount = snapshot?.documents.count ?? 0

                    if playerCount < self.maxPlayers {
                        rooms.append(
                            GameRoom(
                                id: roomId,
                                roomId: roomId,
                                roomNumber: roomNumber,
                                gameType: gameType,
                                hostId: hostId,
                                status: status,
                                currentRound: currentRound,
                                currentTurn: currentTurn,
                                currentTopicIndex: currentTopicIndex,
                                playerCount: playerCount
                            )
                        )
                    }
                }
            }

            group.notify(queue: .main) {
                self.availableRooms = rooms
                print("🔍 Found \(self.availableRooms.count) available rooms")
            }
        }

        roomListeners.append(listener)
    }

    // MARK: - Join Room
    func joinRoom(_ room: GameRoom) {
        refreshLocalPlayerInfo()

        // ✅ FIX: stop browsing listeners (prevents duplicate callbacks + extra updates)
        stopBrowsing()

        connectionStatus = .connecting
        currentRoom = room

        addPlayerToRoom(roomId: room.roomId, isHost: false)

        updatePlayerOnlineStatus(isOnline: true)

        // ✅ FIX: remove any existing listeners before attaching
        detachRoomListeners()
        listenToRoom(roomId: room.roomId)
        listenToRoomPlayers(roomId: room.roomId)

        connectionStatus = .connected
        print("✅ Joined room: \(room.roomNumber)")
    }

    // MARK: - Add Player to Room
    private func addPlayerToRoom(roomId: String, isHost: Bool) {
        refreshLocalPlayerInfo()

        // ✅ FIX: merge=true so we NEVER wipe fields mid-game
        let playerData: [String: Any] = [
            "name": currentPlayerName,
            "score": 0,
            "joinedAt": FieldValue.serverTimestamp(),
            "isReady": false,

            // FunFact defaults
            "hasSubmittedFacts": false,
            "hasVoted": false,
            "isHost": isHost
        ]

        db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .document(currentPlayerId)
            .setData(playerData, merge: true) { error in
                if let error = error {
                    print("❌ Error adding player: \(error.localizedDescription)")
                } else {
                    print("✅ Player added to room (merge)")
                }
            }
    }

    // MARK: - Listen to Room
    private func listenToRoom(roomId: String) {
        roomListener?.remove()
        roomListener = nil

        roomListener = db.collection("gameRooms")
            .document(roomId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error listening to room: \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data() else { return }

                if let statusStr = data["status"] as? String,
                   let status = RoomStatus(rawValue: statusStr),
                   let currentRound = data["currentRound"] as? Int,
                   let currentTurn = data["currentTurn"] as? String,
                   let currentTopicIndex = data["currentTopicIndex"] as? Int {

                    DispatchQueue.main.async {
                        self.currentRoom?.status = status
                        self.currentRoom?.currentRound = currentRound
                        self.currentRoom?.currentTurn = currentTurn
                        self.currentRoom?.currentTopicIndex = currentTopicIndex

                        let gameState = GameState(
                            status: status,
                            currentRound: currentRound,
                            currentTurn: currentTurn,
                            currentTopicIndex: currentTopicIndex
                        )

                        self.onGameStateChanged?(gameState)
                        print("📊 Game state updated: \(status.rawValue), Round: \(currentRound)")
                    }
                }
            }
    }

    // MARK: - Listen to Room Players
    private func listenToRoomPlayers(roomId: String) {
        playersListener?.remove()
        playersListener = nil

        playersListener = db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error listening to players: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                var players: [GamePlayer] = []

                for doc in documents {
                    let data = doc.data()
                    let playerId = doc.documentID

                    guard let name = data["name"] as? String else { continue }
                    let score = data["score"] as? Int ?? 0
                    let isReady = data["isReady"] as? Bool ?? false

                    // ✅ FIX: prefer stored isHost field (more reliable during transitions)
                    let isHostStored = data["isHost"] as? Bool
                    let computedHost = (playerId == self.currentRoom?.hostId)
                    let isHostFinal = isHostStored ?? computedHost

                    let player = GamePlayer(
                        id: playerId,
                        name: name,
                        score: score,
                        isHost: isHostFinal,
                        isReady: isReady
                    )

                    players.append(player)
                }

                DispatchQueue.main.async {
                    let oldPlayerIds = Set(self.connectedPlayers.map { $0.id })
                    let newPlayerIds = Set(players.map { $0.id })

                    let joinedIds = newPlayerIds.subtracting(oldPlayerIds)
                    for playerId in joinedIds {
                        if let player = players.first(where: { $0.id == playerId }) {
                            print("👋 Player joined: \(player.name)")
                            self.onPlayerJoined?(player)
                        }
                    }

                    let leftIds = oldPlayerIds.subtracting(newPlayerIds)
                    for playerId in leftIds {
                        if let player = self.connectedPlayers.first(where: { $0.id == playerId }) {
                            print("👋 Player left: \(player.name)")
                            self.onPlayerLeft?(player)
                        }
                    }

                    self.connectedPlayers = players
                    self.currentRoom?.playerCount = players.count
                    self.onRoomUpdated?()
                }
            }
    }

    // MARK: - Update Player Ready Status
    func setPlayerReady(_ isReady: Bool) {
        guard let room = currentRoom else { return }

        db.collection("gameRooms")
            .document(room.roomId)
            .collection("players")
            .document(currentPlayerId)
            .setData(["isReady": isReady], merge: true) { error in
                if let error = error {
                    print("❌ Error updating ready status: \(error.localizedDescription)")
                } else {
                    print("✅ Ready status updated: \(isReady)")
                }
            }
    }

    // MARK: - Update Player Score
    func updatePlayerScore(_ playerId: String, score: Int) {
        guard let room = currentRoom else { return }

        db.collection("gameRooms")
            .document(room.roomId)
            .collection("players")
            .document(playerId)
            .setData(["score": score], merge: true)
    }

    // MARK: - Start Game (Host Only)
    func startGame() {
        guard isHosting, let room = currentRoom else { return }

        db.collection("gameRooms").document(room.roomId).updateData([
            "status": "playing"
        ]) { error in
            if let error = error {
                print("❌ Error starting game: \(error.localizedDescription)")
            } else {
                print("🎮 Game started!")
            }
        }
    }

    // MARK: - Update Game State (Host Only)
    func updateGameState(status: RoomStatus? = nil, currentRound: Int? = nil, currentTurn: String? = nil, currentTopicIndex: Int? = nil) {
        guard isHosting, let room = currentRoom else { return }

        var updates: [String: Any] = [:]

        if let status = status { updates["status"] = status.rawValue }
        if let currentRound = currentRound { updates["currentRound"] = currentRound }
        if let currentTurn = currentTurn { updates["currentTurn"] = currentTurn }
        if let currentTopicIndex = currentTopicIndex { updates["currentTopicIndex"] = currentTopicIndex }

        guard !updates.isEmpty else { return }

        db.collection("gameRooms").document(room.roomId).updateData(updates) { error in
            if let error = error {
                print("❌ Error updating game state: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - End Game (Host Only)
    func endGame() {
        guard isHosting, let room = currentRoom else { return }

        db.collection("gameRooms").document(room.roomId).updateData([
            "status": "finished",

            // ✅ IMPORTANT for FunFact navigation
            "currentPhase": "results"
        ]) { [weak self] error in
            if let error = error {
                print("❌ Error ending game: \(error.localizedDescription)")
            } else {
                print("🏁 Game ended!")
                self?.updatePlayerStats()
            }
        }
    }


    // MARK: - Update Player Stats
    private func updatePlayerStats() {
        guard let room = currentRoom else { return }

        db.collection("gameRooms")
            .document(room.roomId)
            .collection("players")
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else { return }

                var maxScore = 0
                var winnerIds: [String] = []

                for doc in documents {
                    let score = doc.data()["score"] as? Int ?? 0
                    if score > maxScore {
                        maxScore = score
                        winnerIds = [doc.documentID]
                    } else if score == maxScore {
                        winnerIds.append(doc.documentID)
                    }
                }

                for doc in documents {
                    let playerId = doc.documentID
                    let isWinner = winnerIds.contains(playerId)

                    self.db.collection("players").document(playerId).setData([
                        "totalGames": FieldValue.increment(Int64(1)),
                        "wins": FieldValue.increment(Int64(isWinner ? 1 : 0)),
                        "coins": FieldValue.increment(Int64(isWinner ? 50 : 10))
                    ], merge: true)
                }
            }
    }

    // MARK: - Leave Room
    func leaveRoom() {
        guard let room = currentRoom else { return }

        db.collection("gameRooms")
            .document(room.roomId)
            .collection("players")
            .document(currentPlayerId)
            .delete()

        if isHosting {
            db.collection("gameRooms").document(room.roomId).delete()
            print("🗑️ Room deleted (host left)")
        }

        cleanup()
    }

    // MARK: - Disconnect
    func disconnect() {
        if currentRoom != nil {
            leaveRoom()
        } else {
            cleanup()
        }
        updatePlayerOnlineStatus(isOnline: false)
    }

    // MARK: - Stop Browsing
    func stopBrowsing() {
        for listener in roomListeners { listener.remove() }
        roomListeners.removeAll()
        availableRooms.removeAll()

        if connectionStatus == .browsing {
            connectionStatus = .disconnected
        }

        print("🛑 Stopped browsing")
    }

    // MARK: - Listener Helpers
    private func detachRoomListeners() {
        playersListener?.remove()
        playersListener = nil

        roomListener?.remove()
        roomListener = nil
    }

    // MARK: - Cleanup
    private func cleanup() {
        for listener in roomListeners { listener.remove() }
        roomListeners.removeAll()

        detachRoomListeners()

        currentRoom = nil
        isHosting = false
        connectedPlayers.removeAll()
        availableRooms.removeAll()
        connectionStatus = .disconnected

        print("🔴 Disconnected and cleaned up")
    }

    deinit {
        cleanup()
    }
}

// MARK: - Models

struct GameRoom: Identifiable, Hashable {
    let id: String
    let roomId: String
    let roomNumber: String
    let gameType: GameType
    let hostId: String
    var status: RoomStatus
    var currentRound: Int
    var currentTurn: String
    var currentTopicIndex: Int
    var playerCount: Int
}

struct GamePlayer: Identifiable, Hashable {
    let id: String
    let name: String
    var score: Int
    let isHost: Bool
    var isReady: Bool
}

struct GameState {
    let status: RoomStatus
    let currentRound: Int
    let currentTurn: String
    let currentTopicIndex: Int
}

enum GameType: String, Codable {
    case fact = "fact"
    case topic = "topics"
    case opinion = "opinion"
}

enum RoomStatus: String, Codable {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
}

// MARK: - Connection Status
enum ConnectionStatus: String {
    case disconnected = "غير متصل"
    case browsing = "البحث عن غرف"
    case hosting = "استضافة غرفة"
    case connecting = "جاري الاتصال"
    case connected = "متصل"
}

// MARK: - Game Message (for compatibility)
struct GameMessage: Codable {
    let type: String
    let senderId: String
    let payload: [String: String]?
}

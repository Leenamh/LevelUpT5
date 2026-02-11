//
//  FunFactViewModel.swift
//  Bashkah - Fun Fact Game
//
//  ViewModel للعبة هات العلم فقط
//  Created by Hneen on 22/08/1447 AH.
//

import Foundation
import Combine

class FunFactViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPlayer: FunFactPlayer?
    @Published var gameRoom: FunFactRoom?
    @Published var currentPlayerFacts: [String] = Array(repeating: "", count: 5)
    @Published var currentFactIndex: Int = 0
    @Published var selectedVote: UUID? = nil
    @Published var showingAnswer: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var finalResults: [PlayerScore] = []
    
    // MARK: - Multipeer Manager
    let multipeerManager = MultipeerManager()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupMultipeerCallbacks()
    }
    
    // MARK: - Setup Multipeer Callbacks
    private func setupMultipeerCallbacks() {
        multipeerManager.onMessageReceived = { [weak self] message in
            self?.handleReceivedMessage(message)
        }
        
        multipeerManager.onPeerConnectionChanged = { [weak self] in
            self?.handlePeerConnectionChanged()
        }
    }
    
    // MARK: - Create Room (Host)
    func createRoom(playerName: String) {
        let roomNumber = String(format: "%05d", Int.random(in: 10000...99999))
        
        let player = FunFactPlayer(
            name: playerName,
            deviceID: multipeerManager.deviceID,
            isHost: true
        )
        
        currentPlayer = player
        
        var room = FunFactRoom(
            roomNumber: roomNumber,
            players: [player],
            hostDeviceID: multipeerManager.deviceID
        )
        
        gameRoom = room
        
        // Start hosting
        multipeerManager.hostRoom(roomNumber: roomNumber)
        
        print(" Created Fun Fact room: \(roomNumber)")
    }
    
    // MARK: - Browse Rooms
    func startBrowsing() {
        multipeerManager.startBrowsing()
    }
    
    func stopBrowsing() {
        multipeerManager.stopBrowsing()
    }
    
    // MARK: - Join Room
    func joinRoom(roomNumber: String, playerName: String) {
        isLoading = true
        
        let player = FunFactPlayer(
            name: playerName,
            deviceID: multipeerManager.deviceID
        )
        
        currentPlayer = player
        
        // Join via multipeer
        multipeerManager.joinRoom(roomNumber: roomNumber)
        
        // Send join request after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.sendPlayerJoinedMessage()
        }
    }
    
    // MARK: - Send Player Joined Message
    private func sendPlayerJoinedMessage() {
        guard let player = currentPlayer else { return }
        
        do {
            let playerData = try JSONEncoder().encode(player)
            let message = FunFactMessage(
                type: .playerJoined,
                data: playerData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
            print(" Sent player joined message")
        } catch {
            print(" Error encoding player: \(error)")
            errorMessage = "خطأ في الانضمام"
        }
    }
    
    // MARK: - Submit Facts
    func submitFacts() {
        guard var player = currentPlayer else { return }
        
        // Validate facts
        let validFacts = currentPlayerFacts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard validFacts.count == 5 else {
            errorMessage = "يجب كتابة 5 حقائق"
            return
        }
        
        // Update player facts
        player.facts = currentPlayerFacts
        player.isReady = true
        currentPlayer = player
        
        // Update in room
        gameRoom?.updatePlayer(player)
        
        // Send facts to other players
        do {
            let playerData = try JSONEncoder().encode(player)
            let message = FunFactMessage(
                type: .playerReady,
                data: playerData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
            print(" Facts submitted")
        } catch {
            print("Error submitting facts: \(error)")
            errorMessage = "خطأ في إرسال الحقائق"
        }
    }
    
    // MARK: - Start Game (Host Only)
    func startGame() {
        guard var room = gameRoom, isHost else { return }
        guard room.canStartGame else {
            errorMessage = "ليس كل اللاعبين جاهزين"
            return
        }
        
        // Generate all facts
        room.generateAllFacts()
        
        // Select random joker
        room.selectRandomJoker()
        
        // Update phase
        room.currentPhase = .jokerReveal
        
        gameRoom = room
        
        // Send start game message
        do {
            let roomData = try JSONEncoder().encode(room)
            let message = FunFactMessage(
                type: .startGame,
                data: roomData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
            print(" Game started")
        } catch {
            print("Error starting game: \(error)")
        }
    }
    
    // MARK: - Proceed to Voting (after Joker reveal)
    func proceedToVoting() {
        guard var room = gameRoom else { return }
        room.currentPhase = .voting
        gameRoom = room
        
        if isHost {
            broadcastPhaseChange(.voting)
        }
    }
    
    // MARK: - Submit Vote
    func submitVote(chosenPlayerID: UUID) {
        guard let currentPlayer = currentPlayer,
              let room = gameRoom,
              let currentFact = room.currentFact else { return }
        
        // Prevent double voting
        guard !currentPlayer.hasVoted else { return }
        
        selectedVote = chosenPlayerID
        
        // Create vote
        let vote = FunFactVote(
            factID: currentFact.id,
            voterID: currentPlayer.id,
            chosenPlayerID: chosenPlayerID
        )
        
        // Mark player as voted
        var updatedPlayer = currentPlayer
        updatedPlayer.hasVoted = true
        self.currentPlayer = updatedPlayer
        gameRoom?.updatePlayer(updatedPlayer)
        
        // Send vote
        do {
            let voteData = try JSONEncoder().encode(vote)
            let message = FunFactMessage(
                type: .voteSubmitted,
                data: voteData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
            print(" Vote submitted for player: \(chosenPlayerID)")
        } catch {
            print(" Error submitting vote: \(error)")
        }
        
        // Check if all voted (host only)
        if isHost && room.allPlayersVoted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAnswer()
            }
        }
    }
    
    // MARK: - Show Answer (Host Only)
    private func showAnswer() {
        guard var room = gameRoom, isHost else { return }
        room.currentPhase = .showingAnswer
        gameRoom = room
        showingAnswer = true
        
        broadcastPhaseChange(.showingAnswer)
        
        // Auto proceed to next fact or results
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            self?.proceedToNextOrResults()
        }
    }
    
    // MARK: - Proceed to Next Fact or Results
    private func proceedToNextOrResults() {
        guard var room = gameRoom, isHost else { return }
        
        if room.hasMoreFacts {
            // Next fact
            room.currentFactIndex += 1
            room.currentPhase = .voting
            
            // Reset votes
            for i in 0..<room.players.count {
                room.players[i].hasVoted = false
            }
            
            gameRoom = room
            showingAnswer = false
            selectedVote = nil
            
            // Update current player
            if let updatedPlayer = room.getPlayer(byDeviceID: multipeerManager.deviceID) {
                currentPlayer = updatedPlayer
            }
            
            broadcastRoomUpdate()
        } else {
            // Show results
            showResults()
        }
    }
    
    // MARK: - Show Results
    private func showResults() {
        guard var room = gameRoom else { return }
        room.currentPhase = .results
        gameRoom = room
        
        finalResults = room.calculateScores()
        
        broadcastPhaseChange(.results)
    }
    
    // MARK: - Broadcast Phase Change
    private func broadcastPhaseChange(_ phase: FunFactPhase) {
        guard let room = gameRoom else { return }
        
        do {
            let roomData = try JSONEncoder().encode(room)
            let message = FunFactMessage(
                type: .phaseChanged,
                data: roomData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
        } catch {
            print(" Error broadcasting phase change: \(error)")
        }
    }
    
    // MARK: - Broadcast Room Update
    private func broadcastRoomUpdate() {
        guard let room = gameRoom else { return }
        
        do {
            let roomData = try JSONEncoder().encode(room)
            let message = FunFactMessage(
                type: .roomUpdate,
                data: roomData,
                senderDeviceID: multipeerManager.deviceID
            )
            multipeerManager.broadcastMessage(message)
        } catch {
            print("Error broadcasting room update: \(error)")
        }
    }
    
    // MARK: - Handle Received Messages
    private func handleReceivedMessage(_ message: FunFactMessage) {
        guard let messageData = message.data else { return }
        
        switch message.type {
        case .playerJoined:
            handlePlayerJoined(messageData)
            
        case .playerReady:
            handlePlayerReady(messageData)
            
        case .startGame:
            handleStartGame(messageData)
            
        case .voteSubmitted:
            handleVoteSubmitted(messageData)
            
        case .roomUpdate:
            handleRoomUpdate(messageData)
            
        case .phaseChanged:
            handlePhaseChanged(messageData)
            
        default:
            break
        }
    }
    
    // MARK: - Handle Player Joined
    private func handlePlayerJoined(_ data: Data) {
        guard let player = try? JSONDecoder().decode(FunFactPlayer.self, from: data) else { return }
        
        // Add player (host only)
        if isHost {
            let added = gameRoom?.addPlayer(player) ?? false
            if added {
                print(" Player joined: \(player.name)")
                broadcastRoomUpdate()
            }
        }
    }
    
    // MARK: - Handle Player Ready
    private func handlePlayerReady(_ data: Data) {
        guard let player = try? JSONDecoder().decode(FunFactPlayer.self, from: data) else { return }
        
        gameRoom?.updatePlayer(player)
        print(" Player ready: \(player.name)")
    }
    
    // MARK: - Handle Start Game
    private func handleStartGame(_ data: Data) {
        guard let room = try? JSONDecoder().decode(FunFactRoom.self, from: data) else { return }
        
        gameRoom = room
        print(" Game started - Phase: \(room.currentPhase)")
    }
    
    // MARK: - Handle Vote Submitted
    private func handleVoteSubmitted(_ data: Data) {
        guard let vote = try? JSONDecoder().decode(FunFactVote.self, from: data),
              var room = gameRoom else { return }
        
        // Update vote in room
        if let factIndex = room.allFacts.firstIndex(where: { $0.id == vote.factID }) {
            room.allFacts[factIndex].votes[vote.voterID] = vote.chosenPlayerID
        }
        
        // Update player voted status
        if let playerIndex = room.players.firstIndex(where: { $0.id == vote.voterID }) {
            room.players[playerIndex].hasVoted = true
        }
        
        gameRoom = room
        print(" Vote received from: \(vote.voterID)")
        
        // Host checks if all voted
        if isHost && room.allPlayersVoted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAnswer()
            }
        }
    }
    
    // MARK: - Handle Room Update
    private func handleRoomUpdate(_ data: Data) {
        guard let room = try? JSONDecoder().decode(FunFactRoom.self, from: data) else { return }
        
        gameRoom = room
        isLoading = false
        
        // Update current player
        if let updatedPlayer = room.getPlayer(byDeviceID: multipeerManager.deviceID) {
            currentPlayer = updatedPlayer
        }
        
        print(" Room updated")
    }
    
    // MARK: - Handle Phase Changed
    private func handlePhaseChanged(_ data: Data) {
        guard let room = try? JSONDecoder().decode(FunFactRoom.self, from: data) else { return }
        
        gameRoom = room
        
        // Update current player
        if let updatedPlayer = room.getPlayer(byDeviceID: multipeerManager.deviceID) {
            currentPlayer = updatedPlayer
        }
        
        // Handle phase-specific logic
        if room.currentPhase == .showingAnswer {
            showingAnswer = true
        } else if room.currentPhase == .voting {
            showingAnswer = false
            selectedVote = nil
        } else if room.currentPhase == .results {
            finalResults = room.calculateScores()
        }
        
        print(" Phase changed to: \(room.currentPhase)")
    }
    
    // MARK: - Handle Peer Connection Changed
    private func handlePeerConnectionChanged() {
        print(" Connected peers: \(multipeerManager.connectedPeers.count)")
    }
    
    // MARK: - Leave Room
    func leaveRoom() {
        multipeerManager.disconnect()
        currentPlayer = nil
        gameRoom = nil
        currentPlayerFacts = Array(repeating: "", count: 5)
        currentFactIndex = 0
        selectedVote = nil
        showingAnswer = false
        finalResults = []
    }
    
    // MARK: - Helper Properties
    var isHost: Bool {
        return currentPlayer?.isHost ?? false
    }
    
    var isJoker: Bool {
        guard let playerID = currentPlayer?.id,
              let jokerID = gameRoom?.jokerPlayerID else { return false }
        return playerID == jokerID
    }
    
    var canStartGame: Bool {
        return isHost && (gameRoom?.canStartGame ?? false)
    }
    
    var availableRooms: [String] {
        return Array(multipeerManager.availableRooms.keys).sorted()
    }
}

//
//  FunFactViewModel.swift
//  Bashkah
//
//  COMPLETE WITH AUTO-START FIX - 15/02/2026
//

import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

class FunFactViewModel: ObservableObject {
    // MARK: - Published Properties (State)
    @Published var currentPlayer: FunFactPlayer?
    @Published var gameRoom: FunFactRoom?
    @Published var currentPlayerFacts: [String] = Array(repeating: "", count: 5)
    @Published var currentFactIndex: Int = 0
    @Published var selectedVote: UUID? = nil
    @Published var showingAnswer: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var finalResults: [PlayerScore] = []
    @Published var currentDisplayFact: FunFact?
    
    // MARK: - Navigation Published Properties
    @Published var navigateToWriting: Bool = false
    @Published var showExitAlert: Bool = false
    
    // MARK: - Firebase Manager
    let firebaseManager = FirebaseMultiplayerManager()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var factsListener: ListenerRegistration?
    private var votesListener: ListenerRegistration?
    private var roomPhaseListener: ListenerRegistration?
    private var playersListener: ListenerRegistration?
    private var waitingCallback: ((Bool) -> Void)?
    
    private var currentPlayerId: String {
        UserDefaults.standard.string(forKey: "playerId") ?? UUID().uuidString
    }
    private var currentPlayerName: String {
        UserDefaults.standard.string(forKey: "playerName") ?? "Player"
    }
    
    // MARK: - Computed Properties
    var roomNumber: String {
        gameRoom?.roomNumber ?? "-----"
    }
    
    var playerCount: Int {
        firebaseManager.connectedPlayers.count
    }
    
    var players: [GamePlayer] {
        firebaseManager.connectedPlayers
    }
    
    var isHost: Bool {
        currentPlayer?.isHost ?? false
    }
    
    var isJoker: Bool {
        guard let playerID = currentPlayer?.id,
              let jokerID = gameRoom?.jokerPlayerID else { return false }
        return playerID == jokerID
    }
    
    var canStartGame: Bool {
        isHost && (gameRoom?.canStartGame ?? false)
    }
    
    var canStartWriting: Bool {
        isHost && firebaseManager.connectedPlayers.count >= 2
    }
    
    var availableRooms: [String] {
        firebaseManager.availableRooms.map { $0.roomNumber }.sorted()
    }
    
    // MARK: - Initialization
    init() {
        setupFirebaseCallbacks()
    }
    
    // MARK: - Setup Firebase Callbacks
    private func setupFirebaseCallbacks() {
        firebaseManager.onPlayerJoined = { [weak self] player in
            self?.handlePlayerJoined(player)
        }
        
        firebaseManager.onPlayerLeft = { [weak self] player in
            self?.handlePlayerLeft(player)
        }
        
        firebaseManager.onGameStateChanged = { [weak self] state in
            self?.handleGameStateChanged(state)
        }
        
        firebaseManager.onRoomUpdated = { [weak self] in
            self?.handleRoomUpdated()
        }
    }
    
    // MARK: - Room Lobby Logic
    func setupRoomLobby() {
        setupGameListeners()
        print("🏠 Room lobby setup complete")
    }
    
    func copyRoomNumber() {
        UIPasteboard.general.string = gameRoom?.roomNumber
        print("📋 Room number copied: \(gameRoom?.roomNumber ?? "")")
    }
    
    func angleForPlayer(at index: Int) -> Double {
        let total = firebaseManager.connectedPlayers.count
        let angleStep = (2 * .pi) / Double(total)
        return angleStep * Double(index) - .pi / 2
    }
    
    func handleLeaveRoom() {
        leaveRoom()
    }
    
    // MARK: - Start Writing Phase (Host Action)
    func startWritingPhase() {
        guard isHost else {
            print("⚠️ Only host can start writing phase")
            return
        }
        
        guard canStartWriting else {
            errorMessage = "يجب أن يكون هناك لاعبان على الأقل"
            return
        }
        
        isLoading = true
        
        guard let roomId = firebaseManager.currentRoom?.roomId else {
            isLoading = false
            return
        }
        
        // Select random joker
        let randomPlayer = firebaseManager.connectedPlayers.randomElement()
        let jokerId = randomPlayer?.id ?? currentPlayerId
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .updateData([
                "currentPhase": "writingFacts",
                "status": "playing",
                "jokerPlayerId": jokerId,
                "currentFactIndex": 0
            ]) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Error updating phase: \(error.localizedDescription)")
                        self?.errorMessage = "حدث خطأ أثناء بدء اللعبة"
                    } else {
                        print("✅ Writing phase started - Joker: \(jokerId)")
                        self?.gameRoom?.jokerPlayerID = UUID(uuidString: jokerId)
                        self?.navigateToWriting = true
                    }
                }
            }
    }
    
    // MARK: - Create Room (Host)
    func createRoom(playerName: String) {
        let roomNumber = String(format: "%05d", Int.random(in: 10000...99999))
        
        let player = FunFactPlayer(
            name: playerName,
            deviceID: currentPlayerId,
            isHost: true
        )
        
        currentPlayer = player
        
        // Create room in Firebase
        firebaseManager.hostRoom(roomNumber: roomNumber, gameType: .fact)
        
        // Initialize local room structure
        var room = FunFactRoom(
            roomNumber: roomNumber,
            players: [player],
            hostDeviceID: currentPlayerId
        )
        
        gameRoom = room
        
        print("🟢 Created Fun Fact room: \(roomNumber)")
    }
    
    // MARK: - Browse Rooms
    func startBrowsing() {
        firebaseManager.startBrowsing(for: .fact)
    }
    
    func stopBrowsing() {
        firebaseManager.stopBrowsing()
    }
    
    // MARK: - Join Room
    func joinRoom(roomNumber: String, playerName: String) {
        isLoading = true
        errorMessage = nil
        
        let player = FunFactPlayer(
            name: playerName,
            deviceID: currentPlayerId
        )
        
        currentPlayer = player
        
        // Find room by number
        if let room = firebaseManager.availableRooms.first(where: { $0.roomNumber == roomNumber }) {
            firebaseManager.joinRoom(room)
            
            // Initialize local room structure
            let localRoom = FunFactRoom(
                roomNumber: roomNumber,
                players: [player],
                hostDeviceID: room.hostId
            )
            gameRoom = localRoom
            
            // Wait for Firebase to sync, then set loading false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isLoading = false
                print("✅ Joined room: \(roomNumber)")
            }
        } else {
            errorMessage = "الغرفة غير موجودة"
            isLoading = false
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
        
        // Store each fact in Firebase
        for (index, factText) in validFacts.enumerated() {
            storeFact(text: factText, index: index)
        }
        
        // Mark player as submitted
        markPlayerFactsSubmitted()
        
        // Set ready status
        firebaseManager.setPlayerReady(true)
        
        print("✅ All 5 facts submitted successfully")
        
        // Check if all players submitted (host only)
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkIfAllPlayersSubmittedFacts()
            }
        }
    }
    
    // MARK: - Store Fact
    private func storeFact(text: String, index: Int) {
        guard let roomId = firebaseManager.currentRoom?.roomId,
              let playerId = currentPlayer?.id,
              let playerName = currentPlayer?.name else {
            print("❌ Missing room or player info")
            return
        }
        
        let factData: [String: Any] = [
            "playerId": playerId.uuidString,
            "playerName": playerName,
            "text": text,
            "orderIndex": -1,  // Will be updated when shuffled
            "createdAt": FieldValue.serverTimestamp(),
            "isRevealed": false,
            "votesReceived": 0
        ]
        
        // Auto-generate document ID
        let factRef = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document()
        
        factRef.setData(factData) { error in
            if let error = error {
                print("❌ Error storing fact: \(error.localizedDescription)")
            } else {
                print("✅ Fact stored: \(text)")
            }
        }
    }
    
    // MARK: - Mark Player Facts Submitted
    private func markPlayerFactsSubmitted() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .document(currentPlayerId)
            .updateData([
                "hasSubmittedFacts": true,
                "isReady": true
            ])
    }
    
    // MARK: - Check If All Players Submitted Facts (Host Only) - FIXED
    func checkIfAllPlayersSubmittedFacts() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId else {
            print("⚠️ Not host or no room ID")
            return
        }
        
        print("🔍 Checking if all players submitted facts...")
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error checking players: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No player documents found")
                    return
                }
                
                print("📊 Total players in Firebase: \(documents.count)")
                
                var readyCount = 0
                
                for doc in documents {
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unknown"
                    let hasSubmitted = data["hasSubmittedFacts"] as? Bool ?? false
                    
                    print("   \(name): \(hasSubmitted ? "✅ Ready" : "⏳ Writing")")
                    
                    if hasSubmitted {
                        readyCount += 1
                    }
                }
                
                print("📈 Ready players: \(readyCount)/\(documents.count)")
                
                if readyCount == documents.count && documents.count > 0 {
                    print("🎉 ALL PLAYERS READY - STARTING SHUFFLE!")
                    
                    DispatchQueue.main.async {
                        self.shuffleAndPrepareVoting()
                    }
                } else {
                    print("⏳ Still waiting for \(documents.count - readyCount) player(s)")
                }
            }
    }
    
    // MARK: - Manual Start Voting (Backup for Host)
    func manualStartVoting() {
        guard isHost else {
            print("⚠️ Only host can manually start")
            return
        }
        
        print("🎯 Manual start triggered by host!")
        checkIfAllPlayersSubmittedFacts()
    }
    
    // MARK: - Shuffle Facts and Prepare Voting (Host Only)
    private func shuffleAndPrepareVoting() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId else {
            print("❌ Cannot shuffle - not host or no room")
            return
        }
        
        print("🎲 Starting shuffle process...")
        
        // Get all facts
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error getting facts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No fact documents found")
                    return
                }
                
                print("📝 Found \(documents.count) facts to shuffle")
                
                // Shuffle the order
                var shuffledIndices = Array(0..<documents.count).shuffled()
                
                print("🔀 Shuffled order: \(shuffledIndices)")
                
                // Update orderIndex for each fact
                let batch = self.firebaseManager.db.batch()
                
                for (newIndex, doc) in documents.enumerated() {
                    let factRef = doc.reference
                    batch.updateData(["orderIndex": shuffledIndices[newIndex]], forDocument: factRef)
                }
                
                // Mark facts as shuffled in room
                let roomRef = self.firebaseManager.db.collection("gameRooms").document(roomId)
                batch.updateData([
                    "factsShuffled": true,
                    "currentFactIndex": 0,
                    "currentPhase": "voting"
                ], forDocument: roomRef)
                
                // Commit batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Batch commit error: \(error.localizedDescription)")
                    } else {
                        print("✅ SHUFFLE COMPLETE - Phase set to voting")
                        
                        DispatchQueue.main.async {
                            self.gameRoom?.currentPhase = .voting
                            self.loadCurrentFact()
                        }
                    }
                }
            }
    }
    
    // MARK: - Load Current Fact
    func loadCurrentFact() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        // Get current index from Firebase
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let currentIndex = data["currentFactIndex"] as? Int else { return }
                
                // Query for fact with current orderIndex
                self.firebaseManager.db.collection("gameRooms")
                    .document(roomId)
                    .collection("facts")
                    .whereField("orderIndex", isEqualTo: currentIndex)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self,
                              let document = snapshot?.documents.first else {
                            print("❌ No fact found at index \(currentIndex)")
                            return
                        }
                        
                        let data = document.data()
                        let factId = document.documentID
                        let playerId = data["playerId"] as? String ?? ""
                        let playerName = data["playerName"] as? String ?? ""
                        let text = data["text"] as? String ?? ""
                        let isRevealed = data["isRevealed"] as? Bool ?? false
                        
                        DispatchQueue.main.async {
                            let fact = FunFact(
                                id: UUID(uuidString: factId) ?? UUID(),
                                playerID: UUID(uuidString: playerId) ?? UUID(),
                                playerName: playerName,
                                text: text,
                                isRevealed: isRevealed
                            )
                            
                            self.currentDisplayFact = fact
                            self.gameRoom?.currentFactIndex = currentIndex
                            
                            print("✅ Loaded fact: \(text)")
                        }
                    }
            }
    }
    
    // MARK: - Proceed to Voting
    func proceedToVoting() {
        guard var room = gameRoom else { return }
        room.currentPhase = .voting
        gameRoom = room
        
        if isHost {
            updateRoomPhase(to: "voting")
        }
    }
    
    // MARK: - Submit Vote
    func submitVote(chosenPlayerID: UUID) {
        guard let currentPlayer = currentPlayer,
              let roomId = firebaseManager.currentRoom?.roomId,
              let currentFact = currentDisplayFact else {
            print("❌ Missing data for vote submission")
            return
        }
        
        guard !currentPlayer.hasVoted else {
            print("⚠️ Player already voted")
            return
        }
        
        selectedVote = chosenPlayerID
        
        let isCorrect = chosenPlayerID == currentFact.playerID
        
        let voteData: [String: Any] = [
            "voterId": currentPlayer.id.uuidString,
            "factId": currentFact.id.uuidString,
            "chosenPlayerId": chosenPlayerID.uuidString,
            "isCorrect": isCorrect,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Use voterId as document ID to prevent duplicate votes
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .document(currentPlayer.id.uuidString)
            .setData(voteData) { [weak self] error in
                if let error = error {
                    print("❌ Error submitting vote: \(error.localizedDescription)")
                } else {
                    print("✅ Vote submitted for: \(chosenPlayerID)")
                    
                    // Update local state
                    var updatedPlayer = currentPlayer
                    updatedPlayer.hasVoted = true
                    self?.currentPlayer = updatedPlayer
                    
                    // Update player voted status in Firebase
                    self?.markPlayerVoted()
                    
                    // Increment vote count
                    self?.incrementFactVoteCount(factId: currentFact.id.uuidString)
                }
            }
    }
    
    // MARK: - Handle Time Up
    func handleTimeUp() {
        // When timer expires and player hasn't voted
        guard var player = currentPlayer else { return }
        
        player.hasVoted = true
        self.currentPlayer = player
        
        // Mark as voted in Firebase (but no points awarded)
        markPlayerVoted()
        
        print("⏰ Time's up! Player didn't vote")
    }
    
    // MARK: - Mark Player Voted
    private func markPlayerVoted() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .document(currentPlayerId)
            .updateData(["hasVoted": true])
    }
    
    // MARK: - Increment Fact Vote Count
    private func incrementFactVoteCount(factId: String) {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        let factRef = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document(factId)
        
        factRef.updateData([
            "votesReceived": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Check if All Voted (Host Only)
    private func checkIfAllVoted() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        let totalPlayers = firebaseManager.connectedPlayers.count
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let count = snapshot?.documents.count else { return }
                
                if count >= totalPlayers {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.revealAnswer()
                    }
                }
            }
    }
    
    // MARK: - Reveal Answer (Host Only)
    func revealAnswer() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId,
              let currentFact = currentDisplayFact else { return }
        
        let factRef = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document(currentFact.id.uuidString)
        
        // Mark fact as revealed
        factRef.updateData([
            "isRevealed": true
        ]) { [weak self] error in
            if let error = error {
                print("❌ Error revealing answer: \(error.localizedDescription)")
            } else {
                print("✅ Answer revealed: \(currentFact.playerName)")
                
                // Update phase
                self?.updateRoomPhase(to: "showingAnswer")
                
                // Calculate points (1 coin per correct answer)
                self?.calculatePointsForCurrentFact()
                
                // Wait then move to next
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self?.moveToNextFactOrResults()
                }
            }
        }
    }
    
    // MARK: - Calculate Points for Current Fact (1 coin per correct vote)
    private func calculatePointsForCurrentFact() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        // Get all correct votes
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .whereField("isCorrect", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // Award 1 coin for each correct vote
                for doc in documents {
                    let data = doc.data()
                    let voterId = data["voterId"] as? String ?? ""
                    self?.awardPoints(to: voterId, points: 1)
                }
            }
    }
    
    // MARK: - Award Points (Coins)
    private func awardPoints(to playerId: String, points: Int) {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        // Award points in room
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .document(playerId)
            .updateData([
                "score": FieldValue.increment(Int64(points))
            ]) { error in
                if let error = error {
                    print("❌ Error awarding points: \(error.localizedDescription)")
                } else {
                    print("✅ Awarded \(points) coin(s) to \(playerId)")
                    
                    // Update local player score
                    DispatchQueue.main.async { [weak self] in
                        if var player = self?.currentPlayer, player.deviceID == playerId {
                            player.score += points
                            self?.currentPlayer = player
                        }
                    }
                }
            }
    }
    
    // MARK: - Move to Next Fact or Results
    private func moveToNextFactOrResults() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId,
              var room = gameRoom else { return }
        
        // Get total number of facts
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let totalFacts = snapshot?.documents.count else { return }
                
                if room.currentFactIndex < totalFacts - 1 {
                    // Move to next fact
                    let nextIndex = room.currentFactIndex + 1
                    
                    // Clear votes
                    self.clearVotes()
                    
                    // Reset player voted status
                    self.resetPlayerVotedStatus()
                    
                    // Update room
                    self.firebaseManager.db.collection("gameRooms")
                        .document(roomId)
                        .updateData([
                            "currentFactIndex": nextIndex,
                            "currentPhase": "voting"
                        ]) { error in
                            if let error = error {
                                print("❌ Error moving to next fact: \(error.localizedDescription)")
                            } else {
                                print("✅ Moving to fact \(nextIndex + 1)/\(totalFacts)")
                                
                                DispatchQueue.main.async {
                                    room.currentFactIndex = nextIndex
                                    self.gameRoom = room
                                    self.showingAnswer = false
                                    self.selectedVote = nil
                                    self.loadCurrentFact()
                                }
                            }
                        }
                } else {
                    // All facts done - show results
                    self.finishGame()
                }
            }
    }
    
    // MARK: - Clear Votes
    private func clearVotes() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let batch = self?.firebaseManager.db.batch()
                for doc in documents {
                    batch?.deleteDocument(doc.reference)
                }
                batch?.commit()
            }
    }
    
    // MARK: - Reset Player Voted Status
    private func resetPlayerVotedStatus() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let batch = self?.firebaseManager.db.batch()
                for doc in documents {
                    batch?.updateData(["hasVoted": false], forDocument: doc.reference)
                }
                batch?.commit()
                
                // Reset local state
                DispatchQueue.main.async {
                    if var player = self?.currentPlayer {
                        player.hasVoted = false
                        self?.currentPlayer = player
                    }
                }
            }
    }
    
    // MARK: - Finish Game
    private func finishGame() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .updateData([
                "currentPhase": "results",
                "status": "finished"
            ]) { [weak self] error in
                if let error = error {
                    print("❌ Error finishing game: \(error.localizedDescription)")
                } else {
                    print("✅ Game finished - showing results")
                    self?.loadFinalScores()
                    self?.firebaseManager.endGame()
                }
            }
    }
    
    // MARK: - Load Final Scores
    func loadFinalScores() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .order(by: "score", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                var scores: [PlayerScore] = []
                
                for (index, doc) in documents.enumerated() {
                    let data = doc.data()
                    let playerId = doc.documentID
                    let name = data["name"] as? String ?? ""
                    let score = data["score"] as? Int ?? 0
                    
                    let playerScore = PlayerScore(
                        playerID: UUID(uuidString: playerId) ?? UUID(),
                        playerName: name,
                        score: score,
                        rank: index + 1
                    )
                    scores.append(playerScore)
                }
                
                DispatchQueue.main.async {
                    self.finalResults = scores
                    print("✅ Final scores loaded: \(scores.count) players")
                }
            }
    }
    
    // MARK: - Update Room Phase
    private func updateRoomPhase(to phase: String) {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .updateData(["currentPhase": phase])
    }
    
    // MARK: - Setup Waiting Listener - FIXED WITH AUTO-START
    func setupWaitingListener(onNavigate: @escaping (Bool) -> Void) {
        self.waitingCallback = onNavigate
        
        guard let roomId = firebaseManager.currentRoom?.roomId else {
            print("❌ No room ID for waiting listener")
            return
        }
        
        print("🎯 Setting up waiting listener for room: \(roomId)")
        print("   Is Host: \(isHost)")
        
        // Listen for voting phase (all players)
        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                if let phase = data["currentPhase"] as? String {
                    print("📱 Phase changed to: \(phase)")
                    
                    if phase == "voting" {
                        DispatchQueue.main.async {
                            print("✅ Navigating to voting!")
                            self?.waitingCallback?(true)
                        }
                    }
                }
            }
        
        // 🔧 CRITICAL FIX: Host listens to player readiness in real-time
        if isHost {
            print("👑 Host is setting up player listener...")
            
            playersListener = firebaseManager.db.collection("gameRooms")
                .document(roomId)
                .collection("players")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Player listener error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("❌ No player documents")
                        return
                    }
                    
                    print("🔄 Player status changed! Checking readiness...")
                    
                    // Check if all are ready
                    var readyCount = 0
                    var totalPlayers = documents.count
                    
                    for doc in documents {
                        let data = doc.data()
                        let name = data["name"] as? String ?? "Unknown"
                        let hasSubmitted = data["hasSubmittedFacts"] as? Bool ?? false
                        
                        print("   \(name): \(hasSubmitted ? "✅" : "⏳")")
                        
                        if hasSubmitted {
                            readyCount += 1
                        }
                    }
                    
                    print("📊 Ready: \(readyCount)/\(totalPlayers)")
                    
                    // If all ready, start the game
                    if readyCount == totalPlayers && totalPlayers > 0 {
                        print("🎉 ALL PLAYERS READY - AUTO-STARTING!")
                        
                        // Small delay to ensure UI is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.shuffleAndPrepareVoting()
                        }
                    }
                }
        }
    }
    
    // MARK: - Setup Game Listeners
    func setupGameListeners() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        
        // Listen to room phase changes
        roomPhaseListener = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                DispatchQueue.main.async {
                    // Handle phase changes
                    if let phaseStr = data["currentPhase"] as? String {
                        switch phaseStr {
                        case "writingFacts":
                            self?.navigateToWriting = true
                        case "voting":
                            self?.showingAnswer = false
                            self?.selectedVote = nil
                            self?.loadCurrentFact()
                        case "showingAnswer":
                            self?.showingAnswer = true
                        case "results":
                            self?.loadFinalScores()
                        default:
                            break
                        }
                    }
                    
                    // Update joker
                    if let jokerId = data["jokerPlayerId"] as? String {
                        self?.gameRoom?.jokerPlayerID = UUID(uuidString: jokerId)
                    }
                }
            }
        
        // Listen to votes
        votesListener = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let count = snapshot?.documents.count else { return }
                
                print("📊 Votes received: \(count)")
                
                // Host checks if all voted
                if self.isHost {
                    let totalPlayers = self.firebaseManager.connectedPlayers.count
                    if count >= totalPlayers {
                        self.checkIfAllVoted()
                    }
                }
            }
    }
    
    // MARK: - Handle Player Joined
    private func handlePlayerJoined(_ player: GamePlayer) {
        guard var room = gameRoom else {
            print("⚠️ No room when player joined")
            return
        }
        
        // Check if player already exists
        if room.players.contains(where: { $0.deviceID == player.id }) {
            print("ℹ️ Player already in room: \(player.name)")
            return
        }
        
        let funFactPlayer = FunFactPlayer(
            name: player.name,
            deviceID: player.id,
            isHost: player.isHost
        )
        
        let added = room.addPlayer(funFactPlayer)
        if added {
            self.gameRoom = room
            print("👋 Player joined successfully: \(player.name)")
        }
        
        // Set loading false when player successfully joins
        if player.id == currentPlayerId {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Handle Player Left
    private func handlePlayerLeft(_ player: GamePlayer) {
        print("👋 Player left: \(player.name)")
        gameRoom?.players.removeAll { $0.deviceID == player.id }
    }
    
    // MARK: - Handle Game State Changed
    private func handleGameStateChanged(_ state: GameState) {
        print("📊 Game state: \(state.status.rawValue)")
    }
    
    // MARK: - Handle Room Updated
    private func handleRoomUpdated() {
        print("🔄 Room updated")
        syncPlayers()
    }
    
    // MARK: - Sync Players
    private func syncPlayers() {
        guard var room = gameRoom else { return }
        
        for firebasePlayer in firebaseManager.connectedPlayers {
            if let index = room.players.firstIndex(where: { $0.deviceID == firebasePlayer.id }) {
                room.players[index].isReady = firebasePlayer.isReady
            }
        }
        
        gameRoom = room
    }
    
    // MARK: - Cleanup
    func cleanup() {
        factsListener?.remove()
        votesListener?.remove()
        roomPhaseListener?.remove()
        playersListener?.remove()
        cancellables.removeAll()
    }
    
    // MARK: - Leave Room
    func leaveRoom() {
        cleanup()
        firebaseManager.disconnect()
        currentPlayer = nil
        gameRoom = nil
        currentPlayerFacts = Array(repeating: "", count: 5)
        currentFactIndex = 0
        selectedVote = nil
        showingAnswer = false
        finalResults = []
        currentDisplayFact = nil
    }
    
    deinit {
        cleanup()
    }
}

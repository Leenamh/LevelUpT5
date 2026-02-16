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

    // ✅ Firestore tracking
    @Published var currentFactDocId: String? = nil
    @Published var currentFactPlayerId: String? = nil

    // MARK: - Navigation Published Properties
    @Published var navigateToWriting: Bool = false
    @Published var showExitAlert: Bool = false

    // ✅ Global phase state for UI (fix stuck navigation)
    @Published var phaseString: String = ""
    @Published var shouldNavigateToVoting: Bool = false

    // MARK: - Firebase Manager
    let firebaseManager = FirebaseMultiplayerManager()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var factsListener: ListenerRegistration?
    private var votesListener: ListenerRegistration?
    private var roomPhaseListener: ListenerRegistration?
    private var playersListener: ListenerRegistration?

    // ✅ Voting progression (host)
    private var votingPlayersListener: ListenerRegistration?
    private var lastRevealFactDocId: String? = nil

    // ✅ Guards to stop repeated shuffle during voting
    private var didStartShuffle: Bool = false
    private var latestPhase: String = ""
    private var latestFactsShuffled: Bool = false

    // ✅ Stable player id/name
    private let stablePlayerId: String
    private let stablePlayerName: String

    // ✅ Ensure we don't create multiple room phase listeners
    private var listeningRoomId: String? = nil

    // MARK: - Computed Properties
    var roomNumber: String { gameRoom?.roomNumber ?? "-----" }
    var playerCount: Int { firebaseManager.connectedPlayers.count }
    var players: [GamePlayer] { firebaseManager.connectedPlayers }
    var isHost: Bool { currentPlayer?.isHost ?? false }

    var isJoker: Bool {
        guard let playerID = currentPlayer?.id,
              let jokerID = gameRoom?.jokerPlayerID else { return false }
        return playerID == jokerID
    }

    var canStartGame: Bool { isHost && (gameRoom?.canStartGame ?? false) }
    var canStartWriting: Bool { isHost && firebaseManager.connectedPlayers.count >= 2 }
    var availableRooms: [String] { firebaseManager.availableRooms.map { $0.roomNumber }.sorted() }

    // MARK: - Initialization
    init() {
        if let existing = UserDefaults.standard.string(forKey: "playerId"), !existing.isEmpty {
            stablePlayerId = existing
        } else {
            let newId = UUID().uuidString
            stablePlayerId = newId
            UserDefaults.standard.set(newId, forKey: "playerId")
        }

        if let existingName = UserDefaults.standard.string(forKey: "playerName"), !existingName.isEmpty {
            stablePlayerName = existingName
        } else {
            stablePlayerName = "Player"
        }

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
        startRoomPhaseListenerIfNeeded()   // ✅ important
        print("🏠 Room lobby setup complete")
    }

    func copyRoomNumber() {
        UIPasteboard.general.string = gameRoom?.roomNumber
        print("📋 Room number copied: \(gameRoom?.roomNumber ?? "")")
    }

    func angleForPlayer(at index: Int) -> Double {
        let total = firebaseManager.connectedPlayers.count
        let angleStep = (2 * .pi) / Double(max(total, 1))
        return angleStep * Double(index) - .pi / 2
    }

    func handleLeaveRoom() { leaveRoom() }

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
        didStartShuffle = false
        latestFactsShuffled = false
        shouldNavigateToVoting = false

        guard let roomId = firebaseManager.currentRoom?.roomId else {
            isLoading = false
            return
        }

        let randomPlayer = firebaseManager.connectedPlayers.randomElement()
        let jokerId = randomPlayer?.id ?? stablePlayerId

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .updateData([
                "currentPhase": "writingFacts",
                "status": "playing",
                "jokerPlayerId": jokerId,
                "currentFactIndex": 0,
                "factsShuffled": false
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
                        self?.startRoomPhaseListenerIfNeeded() // ✅ important
                    }
                }
            }
    }

    // MARK: - Create Room (Host)
    func createRoom(playerName: String) {
        UserDefaults.standard.set(playerName, forKey: "playerName")

        let roomNumber = String(format: "%05d", Int.random(in: 10000...99999))

        let player = FunFactPlayer(
            name: playerName,
            deviceID: stablePlayerId,
            isHost: true
        )

        currentPlayer = player

        firebaseManager.hostRoom(roomNumber: roomNumber, gameType: .fact)

        gameRoom = FunFactRoom(
            roomNumber: roomNumber,
            players: [player],
            hostDeviceID: stablePlayerId
        )

        didStartShuffle = false
        latestFactsShuffled = false
        latestPhase = ""
        lastRevealFactDocId = nil
        shouldNavigateToVoting = false

        print("🟢 Created Fun Fact room: \(roomNumber)")
    }

    // MARK: - Browse Rooms
    func startBrowsing() { firebaseManager.startBrowsing(for: .fact) }
    func stopBrowsing() { firebaseManager.stopBrowsing() }

    // MARK: - Join Room
    func joinRoom(roomNumber: String, playerName: String) {
        isLoading = true
        errorMessage = nil
        UserDefaults.standard.set(playerName, forKey: "playerName")
        shouldNavigateToVoting = false

        let player = FunFactPlayer(
            name: playerName,
            deviceID: stablePlayerId
        )

        currentPlayer = player

        if let room = firebaseManager.availableRooms.first(where: { $0.roomNumber == roomNumber }) {
            firebaseManager.joinRoom(room)

            gameRoom = FunFactRoom(
                roomNumber: roomNumber,
                players: [player],
                hostDeviceID: room.hostId
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isLoading = false
                self?.startRoomPhaseListenerIfNeeded() // ✅ important
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

        let validFacts = currentPlayerFacts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard validFacts.count == 5 else {
            errorMessage = "يجب كتابة 5 حقائق"
            return
        }

        player.facts = currentPlayerFacts
        player.isReady = true
        currentPlayer = player

        gameRoom?.updatePlayer(player)

        for (index, factText) in validFacts.enumerated() {
            storeFact(text: factText, index: index)
        }

        markPlayerFactsSubmitted()
        firebaseManager.setPlayerReady(true)

        print("✅ All 5 facts submitted successfully")

        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkIfAllPlayersSubmittedFacts()
            }
        }
    }

    // MARK: - Store Fact
    private func storeFact(text: String, index: Int) {
        guard let roomId = firebaseManager.currentRoom?.roomId,
              let playerName = currentPlayer?.name else {
            print("❌ Missing room or player info")
            return
        }

        let factData: [String: Any] = [
            "playerId": stablePlayerId,
            "playerName": playerName,
            "text": text,
            "orderIndex": -1,
            "createdAt": FieldValue.serverTimestamp(),
            "isRevealed": false,
            "votesReceived": 0
        ]

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document()
            .setData(factData) { error in
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
            .document(stablePlayerId)
            .setData([
                "hasSubmittedFacts": true,
                "isReady": true
            ], merge: true)
    }

    // MARK: - Check If All Players Submitted Facts (Host Only)
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

                var readyCount = 0
                for doc in documents {
                    let data = doc.data()
                    let hasSubmitted = data["hasSubmittedFacts"] as? Bool ?? false
                    if hasSubmitted { readyCount += 1 }
                }

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

    // MARK: - Shuffle Facts and Prepare Voting (Host Only)
    private func shuffleAndPrepareVoting() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId else {
            print("❌ Cannot shuffle - not host or no room")
            return
        }

        if didStartShuffle || latestFactsShuffled || latestPhase == "voting" {
            print("⚠️ Shuffle ignored (already started or already in voting). Phase=\(latestPhase) factsShuffled=\(latestFactsShuffled)")
            return
        }

        didStartShuffle = true
        print("🎲 Starting shuffle process...")

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error getting facts: \(error.localizedDescription)")
                    self.didStartShuffle = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("❌ No fact documents found")
                    self.didStartShuffle = false
                    return
                }

                let shuffledOrder = Array(0..<documents.count).shuffled()
                let batch = self.firebaseManager.db.batch()

                for (i, doc) in documents.enumerated() {
                    batch.updateData(["orderIndex": shuffledOrder[i]], forDocument: doc.reference)
                }

                let roomRef = self.firebaseManager.db.collection("gameRooms").document(roomId)
                batch.updateData([
                    "factsShuffled": true,
                    "currentFactIndex": 0,
                    "currentPhase": "voting"
                ], forDocument: roomRef)

                batch.commit { error in
                    if let error = error {
                        print("❌ Batch commit error: \(error.localizedDescription)")
                        self.didStartShuffle = false
                    } else {
                        print("✅ SHUFFLE COMPLETE - Phase set to voting")
                        self.latestFactsShuffled = true

                        self.playersListener?.remove()
                        self.playersListener = nil

                        DispatchQueue.main.async {
                            self.gameRoom?.currentPhase = .voting
                            self.lastRevealFactDocId = nil
                            self.loadCurrentFact()
                        }
                    }
                }
            }
    }

    // MARK: - Load Current Fact
    func loadCurrentFact() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let currentIndex = data["currentFactIndex"] as? Int else { return }

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
                        let docId = document.documentID
                        let playerIdStr = data["playerId"] as? String ?? ""
                        let playerName = data["playerName"] as? String ?? ""
                        let text = data["text"] as? String ?? ""
                        let isRevealed = data["isRevealed"] as? Bool ?? false

                        DispatchQueue.main.async {
                            self.currentFactDocId = docId
                            self.currentFactPlayerId = playerIdStr

                            let playerUuid = UUID(uuidString: playerIdStr) ?? UUID()

                            self.currentDisplayFact = FunFact(
                                id: UUID(),
                                playerID: playerUuid,
                                playerName: playerName,
                                text: text,
                                isRevealed: isRevealed
                            )


                            self.gameRoom?.currentFactIndex = currentIndex
                            print("✅ Loaded fact: \(text)")
                        }
                    }
            }
    }

    // MARK: - Submit Vote
    func submitVote(chosenPlayerID: UUID) {
        guard let roomId = firebaseManager.currentRoom?.roomId,
              let factDocId = currentFactDocId,
              let currentPlayer = currentPlayer else {
            print("❌ Missing data for vote submission")
            return
        }

        guard !currentPlayer.hasVoted else {
            print("⚠️ Player already voted")
            return
        }

        selectedVote = chosenPlayerID
        let isCorrect = (chosenPlayerID.uuidString == currentFactPlayerId)

        let voteData: [String: Any] = [
            "voterId": stablePlayerId,
            "factDocId": factDocId,
            "chosenPlayerId": chosenPlayerID.uuidString,
            "isCorrect": isCorrect,
            "timestamp": FieldValue.serverTimestamp()
        ]

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .document(stablePlayerId)
            .setData(voteData) { [weak self] error in
                if let error = error {
                    print("❌ Error submitting vote: \(error.localizedDescription)")
                } else {
                    print("✅ Vote submitted for: \(chosenPlayerID)")

                    var updatedPlayer = currentPlayer
                    updatedPlayer.hasVoted = true
                    self?.currentPlayer = updatedPlayer

                    self?.markPlayerVoted()
                    self?.incrementFactVoteCount()
                }
            }
    }

    // MARK: - Handle Time Up
    func handleTimeUp() {
        guard let roomId = firebaseManager.currentRoom?.roomId,
              let factDocId = currentFactDocId,
              var player = currentPlayer else {
            return
        }

        if player.hasVoted || showingAnswer { return }

        player.hasVoted = true
        currentPlayer = player
        markPlayerVoted()

        let timeoutVoteData: [String: Any] = [
            "voterId": stablePlayerId,
            "factDocId": factDocId,
            "chosenPlayerId": "",
            "isCorrect": false,
            "timestamp": FieldValue.serverTimestamp(),
            "didTimeout": true
        ]

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .document(stablePlayerId)
            .setData(timeoutVoteData, merge: true)

        print("⏰ Time's up! Player didn't vote (timeout vote stored)")
    }

    private func markPlayerVoted() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .document(stablePlayerId)
            .setData(["hasVoted": true], merge: true)
    }

    private func incrementFactVoteCount() {
        guard let roomId = firebaseManager.currentRoom?.roomId,
              let docId = currentFactDocId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document(docId)
            .updateData([
                "votesReceived": FieldValue.increment(Int64(1))
            ])
    }

    // MARK: - Reveal Answer (Host Only)
    func revealAnswer() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId,
              let docId = currentFactDocId,
              let playerName = currentDisplayFact?.playerName else { return }

        let factRef = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .document(docId)

        factRef.updateData(["isRevealed": true]) { [weak self] error in
            if let error = error {
                print("❌ Error revealing answer: \(error.localizedDescription)")
            } else {
                print("✅ Answer revealed: \(playerName)")
                self?.updateRoomPhase(to: "showingAnswer")
                self?.calculatePointsForCurrentFact()

                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self?.moveToNextFactOrResults()
                }
            }
        }
    }

    private func calculatePointsForCurrentFact() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .whereField("isCorrect", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                for doc in documents {
                    let data = doc.data()
                    let voterId = data["voterId"] as? String ?? ""
                    self?.awardPoints(to: voterId, points: 1)
                }
            }
    }

    private func awardPoints(to playerId: String, points: Int) {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

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
                    DispatchQueue.main.async { [weak self] in
                        if var player = self?.currentPlayer, player.deviceID == playerId {
                            player.score += points
                            self?.currentPlayer = player
                        }
                    }
                }
            }
    }

    private func moveToNextFactOrResults() {
        guard isHost,
              let roomId = firebaseManager.currentRoom?.roomId,
              var room = gameRoom else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let totalFacts = snapshot?.documents.count else { return }

                if room.currentFactIndex < totalFacts - 1 {
                    let nextIndex = room.currentFactIndex + 1

                    self.clearVotes()
                    self.resetPlayerVotedStatus()

                    self.firebaseManager.db.collection("gameRooms")
                        .document(roomId)
                        .updateData([
                            "currentFactIndex": nextIndex,
                            "currentPhase": "voting"
                        ]) { error in
                            if error == nil {
                                DispatchQueue.main.async {
                                    room.currentFactIndex = nextIndex
                                    self.gameRoom = room
                                    self.showingAnswer = false
                                    self.selectedVote = nil
                                    self.lastRevealFactDocId = nil
                                    self.loadCurrentFact()
                                }
                            }
                        }
                } else {
                    self.finishGame()
                }
            }
    }

    private func clearVotes() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let batch = self?.firebaseManager.db.batch()
                for doc in documents { batch?.deleteDocument(doc.reference) }
                batch?.commit()
            }
    }

    private func resetPlayerVotedStatus() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let batch = self?.firebaseManager.db.batch()
                for doc in documents {
                    batch?.setData(["hasVoted": false], forDocument: doc.reference, merge: true)
                }
                batch?.commit()

                DispatchQueue.main.async {
                    if var player = self?.currentPlayer {
                        player.hasVoted = false
                        self?.currentPlayer = player
                    }
                }
            }
    }

    private func finishGame() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .updateData([
                "currentPhase": "results",
                "status": "finished"
            ]) { [weak self] error in
                if error == nil {
                    self?.loadFinalScores()
                    self?.firebaseManager.endGame()
                }
            }
    }

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
                }
            }
    }

    private func updateRoomPhase(to phase: String) {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }
        firebaseManager.db.collection("gameRooms").document(roomId).updateData(["currentPhase": phase])
    }

    // MARK: - HOST Voting Progression
    private func setupVotingPlayersListenerIfNeeded(roomId: String) {
        guard isHost else { return }

        votingPlayersListener?.remove()
        votingPlayersListener = nil

        votingPlayersListener = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }

                if self.latestPhase != "voting" { return }

                let totalPlayers = docs.count
                let votedPlayers = docs.filter { ($0.data()["hasVoted"] as? Bool) == true }.count

                let currentFactId = self.currentFactDocId
                if currentFactId != nil, currentFactId == self.lastRevealFactDocId {
                    return
                }

                if totalPlayers > 0 && votedPlayers >= totalPlayers {
                    self.lastRevealFactDocId = currentFactId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.revealAnswer()
                    }
                }
            }
    }

    // MARK: - ✅ Single Room Phase Listener (Fix stuck screens)
    func startRoomPhaseListenerIfNeeded() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        if listeningRoomId == roomId, roomPhaseListener != nil {
            return
        }

        listeningRoomId = roomId

        roomPhaseListener?.remove()
        roomPhaseListener = nil

        roomPhaseListener = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() else { return }

                let phase = (data["currentPhase"] as? String) ?? ""
                let shuffled = (data["factsShuffled"] as? Bool) ?? false

                self.latestPhase = phase
                self.latestFactsShuffled = shuffled

                DispatchQueue.main.async {
                    self.phaseString = phase

                    if let idx = data["currentFactIndex"] as? Int {
                        self.gameRoom?.currentFactIndex = idx
                    }

                    switch phase {
                    case "voting":
                        self.showingAnswer = false
                        self.selectedVote = nil
                        if var p = self.currentPlayer { p.hasVoted = false; self.currentPlayer = p }
                        self.lastRevealFactDocId = nil
                        self.loadCurrentFact()
                        self.setupVotingPlayersListenerIfNeeded(roomId: roomId)

                        // ✅ global navigation trigger
                        self.shouldNavigateToVoting = true

                    case "showingAnswer":
                        self.showingAnswer = true
                        self.loadCurrentFact()

                    case "results":
                        self.loadFinalScores()

                    case "writingFacts":
                        self.showingAnswer = false
                        self.selectedVote = nil
                        self.shouldNavigateToVoting = false

                    default:
                        break
                    }
                }
            }

        // Host watches players ONLY during writingFacts
        if isHost {
            playersListener?.remove()
            playersListener = nil

            playersListener = firebaseManager.db.collection("gameRooms")
                .document(roomId)
                .collection("players")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    guard let documents = snapshot?.documents else { return }

                    if self.latestPhase != "writingFacts" || self.latestFactsShuffled || self.didStartShuffle {
                        return
                    }

                    let totalPlayers = documents.count
                    let readyCount = documents.filter { ($0.data()["hasSubmittedFacts"] as? Bool) == true }.count

                    if totalPlayers > 0 && readyCount == totalPlayers {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.shuffleAndPrepareVoting()
                        }
                    }
                }
        }
    }

    // MARK: - Setup Game Listeners
    func setupGameListeners() {
        guard let roomId = firebaseManager.currentRoom?.roomId else { return }

        votesListener?.remove()
        votesListener = nil

        votesListener = firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("votes")
            .addSnapshotListener { snapshot, error in
                let count = snapshot?.documents.count ?? 0
                print("📊 Votes received: \(count)")
            }
    }

    // MARK: - Handle Player Joined
    private func handlePlayerJoined(_ player: GamePlayer) {
        guard var room = gameRoom else { return }

        if room.players.contains(where: { $0.deviceID == player.id }) {
            return
        }

        let funFactPlayer = FunFactPlayer(
            name: player.name,
            deviceID: player.id,
            isHost: player.isHost
        )

        let added = room.addPlayer(funFactPlayer)
        if added { self.gameRoom = room }

        if player.id == stablePlayerId {
            DispatchQueue.main.async { self.isLoading = false }
        }
    }

    private func handlePlayerLeft(_ player: GamePlayer) {
        gameRoom?.players.removeAll { $0.deviceID == player.id }
    }

    private func handleGameStateChanged(_ state: GameState) {
        print("📊 Game state: \(state.status.rawValue)")
    }

    private func handleRoomUpdated() {
        syncPlayers()
    }

    // ✅ Host backup: actually starts voting
    func manualStartVoting() {
        guard isHost else { return }
        print("🚨 Host FORCE starting voting")
        shuffleAndPrepareVoting()
    }

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
        votingPlayersListener?.remove()

        factsListener = nil
        votesListener = nil
        roomPhaseListener = nil
        playersListener = nil
        votingPlayersListener = nil

        lastRevealFactDocId = nil
        cancellables.removeAll()
        listeningRoomId = nil
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
        currentFactDocId = nil
        currentFactPlayerId = nil

        didStartShuffle = false
        latestFactsShuffled = false
        latestPhase = ""
        phaseString = ""
        shouldNavigateToVoting = false
    }

    deinit { cleanup() }
}

//
//  FunFactModels.swift
//  Bashkah - Fun Fact Game
//
//  Model للعبة هات العلم فقط
//  Created by Hneen on 22/08/1447 AH.
//

import Foundation

// MARK: - Player Model
struct FunFactPlayer: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let deviceID: String
    var isHost: Bool
    var isReady: Bool
    var isJoker: Bool
    var score: Int
    var hasVoted: Bool
    var facts: [String]  // 5 facts
    
    init(id: UUID = UUID(), name: String, deviceID: String, isHost: Bool = false, isReady: Bool = false, isJoker: Bool = false, score: Int = 0, hasVoted: Bool = false, facts: [String] = Array(repeating: "", count: 5)) {
        self.id = id
        self.name = name
        self.deviceID = deviceID
        self.isHost = isHost
        self.isReady = isReady
        self.isJoker = isJoker
        self.score = score
        self.hasVoted = hasVoted
        self.facts = facts
    }
    
    var factsComplete: Bool {
        return facts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count == 5
    }
    
    static func == (lhs: FunFactPlayer, rhs: FunFactPlayer) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Fun Fact Model
struct FunFact: Identifiable, Codable, Equatable {
    let id: UUID
    let playerID: UUID
    let playerName: String
    let text: String
    var votes: [UUID: UUID]  // [VoterID: ChosenPlayerID]
    var isRevealed: Bool
    
    init(id: UUID = UUID(), playerID: UUID, playerName: String, text: String, votes: [UUID: UUID] = [:], isRevealed: Bool = false) {
        self.id = id
        self.playerID = playerID
        self.playerName = playerName
        self.text = text
        self.votes = votes
        self.isRevealed = isRevealed
    }
    
    func correctVotesCount() -> Int {
        return votes.values.filter { $0 == playerID }.count
    }
    
    var totalVotes: Int {
        return votes.count
    }
    
    static func == (lhs: FunFact, rhs: FunFact) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Game Room Model
struct FunFactRoom: Codable {
    let id: UUID
    let roomNumber: String
    var players: [FunFactPlayer]
    var currentPhase: FunFactPhase
    var hostDeviceID: String
    var allFacts: [FunFact]
    var currentFactIndex: Int
    var jokerPlayerID: UUID?
    let maxPlayers: Int
    let createdAt: Date
    
    init(id: UUID = UUID(), roomNumber: String, players: [FunFactPlayer] = [], currentPhase: FunFactPhase = .lobby, hostDeviceID: String, allFacts: [FunFact] = [], currentFactIndex: Int = 0, jokerPlayerID: UUID? = nil, maxPlayers: Int = 8, createdAt: Date = Date()) {
        self.id = id
        self.roomNumber = roomNumber
        self.players = players
        self.currentPhase = currentPhase
        self.hostDeviceID = hostDeviceID
        self.allFacts = allFacts
        self.currentFactIndex = currentFactIndex
        self.jokerPlayerID = jokerPlayerID
        self.maxPlayers = maxPlayers
        self.createdAt = createdAt
    }
    
    var isFull: Bool {
        return players.count >= maxPlayers
    }
    
    var allPlayersReady: Bool {
        return !players.isEmpty && players.allSatisfy { $0.isReady }
    }
    
    var allPlayersVoted: Bool {
        return !players.isEmpty && players.allSatisfy { $0.hasVoted }
    }
    
    var canStartGame: Bool {
        return players.count >= 2 && allPlayersReady
    }
    
    mutating func addPlayer(_ player: FunFactPlayer) -> Bool {
        guard !isFull else { return false }
        guard !players.contains(where: { $0.deviceID == player.deviceID }) else { return false }
        players.append(player)
        return true
    }
    
    mutating func removePlayer(deviceID: String) {
        players.removeAll { $0.deviceID == deviceID }
    }
    
    mutating func updatePlayer(_ player: FunFactPlayer) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        }
    }
    
    func getPlayer(byDeviceID deviceID: String) -> FunFactPlayer? {
        return players.first { $0.deviceID == deviceID }
    }
    
    func getPlayer(byID id: UUID) -> FunFactPlayer? {
        return players.first { $0.id == id }
    }
    
    var currentFact: FunFact? {
        guard currentFactIndex < allFacts.count else { return nil }
        return allFacts[currentFactIndex]
    }
    
    var hasMoreFacts: Bool {
        return currentFactIndex < allFacts.count - 1
    }
    
    mutating func generateAllFacts() {
        allFacts.removeAll()
        for player in players {
            for (index, fact) in player.facts.enumerated() where !fact.trimmingCharacters(in: .whitespaces).isEmpty {
                let funFact = FunFact(
                    playerID: player.id,
                    playerName: player.name,
                    text: fact
                )
                allFacts.append(funFact)
            }
        }
        allFacts.shuffle()
    }
    
    mutating func selectRandomJoker() {
        jokerPlayerID = players.randomElement()?.id
    }
    
    func calculateScores() -> [PlayerScore] {
        var scores: [UUID: Int] = [:]
        
        // Initialize scores
        for player in players {
            scores[player.id] = 0
        }
        
        // Calculate scores from votes
        for fact in allFacts {
            let correctVotes = fact.correctVotesCount()
            scores[fact.playerID, default: 0] += (correctVotes * 100)
        }
        
        // Create sorted rankings
        var rankings = scores.map { PlayerScore(playerID: $0.key, playerName: getPlayer(byID: $0.key)?.name ?? "", score: $0.value) }
        rankings.sort { $0.score > $1.score }
        
        // Assign ranks
        for (index, _) in rankings.enumerated() {
            rankings[index].rank = index + 1
        }
        
        return rankings
    }
}

// MARK: - Game Phase Enum
enum FunFactPhase: String, Codable {
    case lobby          // غرفة الانتظار
    case writingFacts   // كتابة الحقائق
    case jokerReveal    // إظهار الجوكر للاعب المحظوظ
    case waitingToStart // انتظار البدء (بعد الجوكر)
    case voting         // التصويت على fact
    case showingAnswer  // عرض الإجابة الصحيحة
    case results        // النتائج النهائية
}

// MARK: - Player Score
struct PlayerScore: Identifiable, Codable {
    let id: UUID
    let playerID: UUID
    let playerName: String
    var score: Int
    var rank: Int
    
    init(id: UUID = UUID(), playerID: UUID, playerName: String, score: Int, rank: Int = 0) {
        self.id = id
        self.playerID = playerID
        self.playerName = playerName
        self.score = score
        self.rank = rank
    }
}

// MARK: - Multipeer Message Types
enum FunFactMessageType: String, Codable {
    case roomUpdate
    case playerJoined
    case playerLeft
    case playerReady
    case factsSubmitted
    case startGame
    case jokerSelected
    case voteSubmitted
    case showAnswer
    case nextFact
    case gameResults
    case phaseChanged
}

// MARK: - Multipeer Message
struct FunFactMessage: Codable {
    let type: FunFactMessageType
    let data: Data?
    let timestamp: Date
    let senderDeviceID: String
    
    init(type: FunFactMessageType, data: Data? = nil, senderDeviceID: String) {
        self.type = type
        self.data = data
        self.timestamp = Date()
        self.senderDeviceID = senderDeviceID
    }
}

// MARK: - Vote Model
struct FunFactVote: Codable {
    let factID: UUID
    let voterID: UUID
    let chosenPlayerID: UUID
    let timestamp: Date
    
    init(factID: UUID, voterID: UUID, chosenPlayerID: UUID) {
        self.factID = factID
        self.voterID = voterID
        self.chosenPlayerID = chosenPlayerID
        self.timestamp = Date()
    }
}

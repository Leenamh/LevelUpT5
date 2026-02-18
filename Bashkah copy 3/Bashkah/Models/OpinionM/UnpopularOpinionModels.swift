//
//  UnpopularOpinionModels.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  UnpopularOpinionModels.swift
//  Bashkah
//
//  Unpopular Opinion Models
//

import Foundation

// MARK: - Player Model
struct UOPlayer: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var opinion: String
    var hasVoted: Bool
    
    init(id: UUID = UUID(), name: String, opinion: String = "", hasVoted: Bool = false) {
        self.id = id
        self.name = name
        self.opinion = opinion
        self.hasVoted = hasVoted
    }
}

// MARK: - Room Model
struct UORoom: Codable, Hashable {
    let id: UUID
    var code: String
    var players: [UOPlayer]
    var currentOpinionIndex: Int
    var votes: [UUID: Bool]
    
    init(id: UUID = UUID(), code: String, players: [UOPlayer], currentOpinionIndex: Int = 0) {
        self.id = id
        self.code = code
        self.players = players
        self.currentOpinionIndex = currentOpinionIndex
        self.votes = [:]
    }
    
    var currentPlayer: UOPlayer? {
        guard currentOpinionIndex < players.count else { return nil }
        return players[currentOpinionIndex]
    }
    
    var agreeCount: Int {
        votes.values.filter { $0 }.count
    }
    
    var disagreeCount: Int {
        votes.values.filter { !$0 }.count
    }
    
    var agreePercentage: Int {
        guard !votes.isEmpty else { return 0 }
        return Int((Double(agreeCount) / Double(votes.count)) * 100)
    }
    
    var disagreePercentage: Int {
        guard !votes.isEmpty else { return 0 }
        return Int((Double(disagreeCount) / Double(votes.count)) * 100)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UORoom, rhs: UORoom) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, code, players, currentOpinionIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        players = try container.decode([UOPlayer].self, forKey: .players)
        currentOpinionIndex = try container.decode(Int.self, forKey: .currentOpinionIndex)
        votes = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(code, forKey: .code)
        try container.encode(players, forKey: .players)
        try container.encode(currentOpinionIndex, forKey: .currentOpinionIndex)
    }
}

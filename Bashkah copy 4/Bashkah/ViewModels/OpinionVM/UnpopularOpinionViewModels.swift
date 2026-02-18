//
//  8.swift
//  Bashkah
//
//  Created by Hneen on 15/08/1447 AH.
//
//
//  UnpopularOpinionViewModels.swift
//  Bashkah
//
//  Created on 24/08/1447 AH.
//

import Foundation
import SwiftUI

// MARK: - Start ViewModel
class UnpopularOpinionStartVM: ObservableObject {
    @Published var name: String = ""
    
    var canStart: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Join ViewModel
class UnpopularOpinionJoinVM: ObservableObject {
    @Published var roomCode: String = ""
    let displayName: String
    
    init(displayName: String) {
        self.displayName = displayName
    }
    
    var canJoin: Bool {
        roomCode.count == 5 && !displayName.isEmpty
    }
}

// MARK: - Writing ViewModel
class UnpopularOpinionWritingVM: ObservableObject {
    @Published var opinion: String = ""
    let roomCode: String
    let playerName: String
    let isHost: Bool
    
    init(roomCode: String, playerName: String, isHost: Bool) {
        self.roomCode = roomCode
        self.playerName = playerName
        self.isHost = isHost
    }
    
    func saveOpinion(_ text: String) {
        self.opinion = text
        // Here you would typically save to your backend/network
    }
}

// MARK: - Lobby ViewModel
class UnpopularOpinionLobbyVM: ObservableObject {
    @Published var room: UORoom
    let isHost: Bool
    
    init(room: UORoom, isHost: Bool) {
        self.room = room
        self.isHost = isHost
    }
    
    var columns: ([UOPlayer], [UOPlayer]) {
        let midIndex = (room.players.count + 1) / 2
        let firstColumn = Array(room.players.prefix(midIndex))
        let secondColumn = Array(room.players.dropFirst(midIndex))
        return (firstColumn, secondColumn)
    }
}

// MARK: - Voting ViewModel
class UnpopularOpinionVotingVM: ObservableObject {
    @Published var room: UORoom
    @Published var hasVoted: Bool = false
    @Published var userVote: Bool? = nil
    let currentPlayerID: UUID
    
    init(room: UORoom, currentPlayerID: UUID) {
        self.room = room
        self.currentPlayerID = currentPlayerID
    }
    
    var currentOpinion: String {
        room.currentPlayer?.opinion ?? ""
    }
    
    var currentPlayerName: String {
        room.currentPlayer?.name ?? ""
    }
    
    func vote(agree: Bool) {
        guard !hasVoted else { return }
        
        userVote = agree
        room.votes[currentPlayerID] = agree
        hasVoted = true
        
        // Here you would typically send vote to backend/network
    }
    
    func nextOpinion() {
        room.currentOpinionIndex += 1
        room.votes.removeAll()
        hasVoted = false
        userVote = nil
    }
}

// MARK: - Results ViewModel
class UnpopularOpinionResultsVM: ObservableObject {
    @Published var room: UORoom
    @Published var showTomatoes: Bool = false
    
    init(room: UORoom) {
        self.room = room
        checkForTomatoes()
    }
    
    var currentOpinion: String {
        room.currentPlayer?.opinion ?? ""
    }
    
    var currentPlayerName: String {
        room.currentPlayer?.name ?? ""
    }
    
    var agreePercentage: Int {
        room.agreePercentage
    }
    
    var disagreePercentage: Int {
        room.disagreePercentage
    }
    
    var shouldShowTomatoes: Bool {
        disagreePercentage > 60 // إذا أكثر من 60% ضد
    }
    
    private func checkForTomatoes() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.shouldShowTomatoes {
                withAnimation {
                    self.showTomatoes = true
                }
            }
        }
    }
}

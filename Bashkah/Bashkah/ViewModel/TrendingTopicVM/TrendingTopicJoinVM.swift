//
//  TrendingTopicJoinVM.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import Foundation

@MainActor
final class TrendingTopicJoinVM: ObservableObject {
    @Published var roomCode: String = ""
    let displayName: String

    init(displayName: String) {
        self.displayName = displayName
    }

    var canJoin: Bool {
        roomCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5
    }
}


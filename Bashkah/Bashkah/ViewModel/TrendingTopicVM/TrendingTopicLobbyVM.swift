//
//  TrendingTopicLobbyVM.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import Foundation
import UIKit

@MainActor
final class TrendingTopicLobbyVM: ObservableObject {
    @Published var room: TTRoom
       let isHost: Bool

       init(room: TTRoom, isHost: Bool) {
           self.room = room
           self.isHost = isHost
       }

       func copyCode() {
           UIPasteboard.general.string = room.code
       }
    
    // Split players into 2 columns (RTL-friendly)
    var columns: ([TTPlayer], [TTPlayer]) {
        var right: [TTPlayer] = []
        var left: [TTPlayer] = []
        for (i, p) in room.players.enumerated() {
            if i % 2 == 0 { right.append(p) } else { left.append(p) }
        }
        return (right, left)
    }
}


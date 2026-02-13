//
//  TTRoom.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  TTRoom.swift
//  Bashkah
//
//  Trending Topic Room Model
//

import Foundation

struct TTRoom: Equatable, Hashable {
    var code: String
    var players: [TTPlayer]
}

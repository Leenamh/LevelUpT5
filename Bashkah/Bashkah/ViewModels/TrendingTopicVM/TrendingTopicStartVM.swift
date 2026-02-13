//
//  TrendingTopicStartVM.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  TrendingTopicStartVM.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import Foundation

@MainActor
final class TrendingTopicStartVM: ObservableObject {
    @Published var name: String = ""

    var canStart: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

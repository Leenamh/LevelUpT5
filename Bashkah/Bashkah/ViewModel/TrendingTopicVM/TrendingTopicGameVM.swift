//
//  TrendingTopicGameVM.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import Foundation

@MainActor
final class TrendingTopicGameVM: ObservableObject {
    @Published var coins: Int = 10
    @Published var topic: String = "TRENDING TOPIC"

    private let mockTopics = [
        "أسعار القهوة المختصة",
        "الدوري السعودي",
        "موسم الرياض",
        "مطاعم جديدة بالرياض",
        "الذكاء الاصطناعي في الدراسة",
        "السيارات الكهربائية"
    ]
    private var idx = 0

    func nextTopic() {
        idx = (idx + 1) % mockTopics.count
        topic = mockTopics[idx]
    }
}


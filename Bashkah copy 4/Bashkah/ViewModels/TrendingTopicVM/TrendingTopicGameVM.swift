//
//  TrendingTopicGameVM.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
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
    @Published var topic: String

    private let mockTopics = [
        "دوام رمضان",
        "العيد",
        "صلاة التراويح",
        "يوم التأسيس السعودي",
        "صلاة الاستسقاء",
        "2026 Winter Olympics – Ice Hockey",
        "فعاليات بوليفارد وورلد",
        "كأس العالم للأندية",
        "حفلات موسم الرياض"
    ]

    init() {
        topic = mockTopics.randomElement() ?? ""
    }

    func nextTopic() {
        topic = mockTopics.randomElement() ?? topic
    }
}

enum CardType: CaseIterable, Identifiable {
    case fact
    case trending
    case unpopular

    var id: Self { self }

    var front: String {
        switch self {
        case .fact: return "FactFront"
        case .trending: return "TrendingTopicsFront"
        case .unpopular: return "unpopularOpinionFront"
        }
    }

    var back: String {
        switch self {
        case .fact: return "FactBack"
        case .trending: return "TrendingTopicsBack"
        case .unpopular: return "unpopularOpinionBack"
        }
    }
}

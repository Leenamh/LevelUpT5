import SwiftUI

final class StartPageViewModel: ObservableObject {

    @Published var cards: [CardType] = [.fact, .trending, .unpopular]

    // Tap on any card
    func bringToFront(_ card: CardType) {
        guard let index = cards.firstIndex(of: card) else { return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
            cards.rotateLeft(by: index)
        }
    }

    // Swipe RIGHT → LEFT
    func swipeLeft() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
            cards.rotateLeft(by: 1)
        }
    }

    // Swipe LEFT → RIGHT
    func swipeRight() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
            cards.rotateRight(by: 1)
        }
    }
}

// MARK: - Array helpers
extension Array {
    mutating func rotateLeft(by positions: Int) {
        guard !isEmpty else { return }
        let p = positions % count
        self = Array(self[p...] + self[..<p])
    }

    mutating func rotateRight(by positions: Int) {
        guard !isEmpty else { return }
        let p = positions % count
        self = Array(self[(count - p)...] + self[..<(count - p)])
    }
}

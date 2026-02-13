import SwiftUI

final class SplashPageViewModel: ObservableObject {

    @Published var spreadCards = false
    @Published var showLogo = false
    @Published var goToStartPage = false

    let cards: [SplashCard] = [
        SplashCard(imageName: "OrangeCard", order: 0),
        SplashCard(imageName: "GreenCard", order: 1),
        SplashCard(imageName: "BlueCard", order: 2)
    ]

    private let spacing: CGFloat = 55

    func offsetX(for card: SplashCard) -> CGFloat {
        guard spreadCards else { return 0 }
        return card.order == 1 ? -spacing : card.order == 2 ? spacing : 0
    }

    func rotation(for card: SplashCard) -> Double {
        guard spreadCards else { return 0 }
        return card.order == 1 ? -12 : card.order == 2 ? 14 : 0
    }

    func zIndex(for card: SplashCard) -> Double {
        card.order == 2 ? 3 : card.order == 0 ? 2 : 1
    }

    func startAnimation() {

        // 1️⃣ Cards fan out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.55)) {
                self.spreadCards = true
            }
        }

        // 2️⃣ Logo appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.showLogo = true
        }

        // 3️⃣ Navigate after 3 seconds from logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.9) {
            self.goToStartPage = true
        }
    }
}

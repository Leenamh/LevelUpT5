import SwiftUI

struct StartPageView: View {
    @StateObject private var vm = StartPageViewModel()

    // 🔴 NEW
    @State private var isFrontCardFlipped = false
    @State private var currentFrontCard: CardType?

    var body: some View {
        ZStack {
            Color("BG").ignoresSafeArea()

            // CARDS
            ZStack {
                ForEach(Array(vm.cards.enumerated()), id: \.element) { index, card in
                    StartPageCardView(
                        frontImage: card.front,
                        backImage: card.back,
                        isFront: index == 0,
                        onFlipChanged: { flipped in
                            if index == 0 {
                                isFrontCardFlipped = flipped
                                currentFrontCard = flipped ? card : nil
                            }
                        },
                        onTap: {
                            vm.bringToFront(card)
                        },
                        onSwipe: { direction in
                            switch direction {
                            case .left:
                                vm.swipeLeft()
                            case .right:
                                vm.swipeRight()
                            }
                        }
                    )
                    .scaleEffect(index == 0 ? 1 : 0.88)
                    .offset(
                        x: xOffset(for: index),
                        y: yOffset(for: index)
                    )
                    .rotationEffect(
                        .degrees(rotation(for: index)),
                        anchor: .bottom
                    )
                    .zIndex(zIndex(for: index))
                }
            }

            // TITLE
            VStack {
                Text("اختر لعبتك")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color("FontColorBlack"))
                    .padding(.top, 90)
                Spacer()
            }

            // 🔴 ACTION BUTTON
            if isFrontCardFlipped, let card = currentFrontCard {
                VStack {
                    Spacer()
                    Button(action: {
                        print("Play \(card)")
                    }) {
                        Text("اللعب")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 208, height: 48)   // ✅ added
                            .background(buttonColor(for: card))
                            .cornerRadius(15)
                            .padding(.horizontal, 110)
                            .padding(.bottom, 60)
                    }
                }
                .transition(.opacity)
            }

        }
        .animation(.easeInOut(duration: 0.25), value: isFrontCardFlipped)
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
    }

    // MARK: - Helpers

    private func buttonColor(for card: CardType) -> Color {
        switch card {
        case .fact:
            return Color("Orange")
        case .trending:
            return Color("DarkBlue")
        case .unpopular:
            return Color("Green2")
        }
    }

    private func xOffset(for index: Int) -> CGFloat {
        switch index {
        case 1: return 60
        case 2: return -60
        default: return 0
        }
    }

    private func yOffset(for index: Int) -> CGFloat {
        index == 0 ? 20 : 32
    }

    private func rotation(for index: Int) -> Double {
        switch index {
        case 1: return 7
        case 2: return -7
        default: return 0
        }
    }

    private func zIndex(for index: Int) -> Double {
        Double(3 - index)
    }
}

#Preview {
    NavigationStack {
        StartPageView()
    }
}

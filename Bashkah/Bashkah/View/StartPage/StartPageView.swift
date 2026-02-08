import SwiftUI

// MARK: - Start Page View

struct StartPageView: View {
    @StateObject private var vm = StartPageViewModel()

    var body: some View {
        ZStack {
            Color("BG").ignoresSafeArea()

            ZStack {
                ForEach(Array(vm.cards.enumerated()), id: \.element) { index, card in
                    StartPageCardView(
                        frontImage: card.front,
                        backImage: card.back,
                        isFront: index == 0,
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

            VStack {
                Text("اختر لعبتك")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color("FontColorBlack"))
                    .padding(.top, 90)
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)   // 🚫 hide back arrow
        .disableSwipeBack()                    // 🚫 disable swipe back
    }

    // MARK: - Layout helpers

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

//////////////////////////////////////////////////////////////
// MARK: - Disable Swipe Back (INLINE)
//////////////////////////////////////////////////////////////

private struct DisableSwipeBack: ViewModifier {
    func body(content: Content) -> some View {
        content.background(DisableSwipeBackController())
    }
}

private struct DisableSwipeBackController: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            controller.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private extension View {
    func disableSwipeBack() -> some View {
        modifier(DisableSwipeBack())
    }
}

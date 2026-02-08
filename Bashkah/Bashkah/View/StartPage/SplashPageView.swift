import SwiftUI

struct SplashPageView: View {

    @StateObject private var vm = SplashPageViewModel()

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {

                // Cards
                ForEach(vm.cards) { card in
                    SplashCardView(imageName: card.imageName)
                        .offset(x: vm.offsetX(for: card))
                        .rotationEffect(
                            .degrees(vm.rotation(for: card)),
                            anchor: .bottom
                        )
                        .zIndex(vm.zIndex(for: card))
                }

                // Logo POP
                if vm.showLogo {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .zIndex(10)
                        .onAppear {
                            withAnimation(
                                .spring(
                                    response: 0.45,
                                    dampingFraction: 0.55
                                )
                            ) {
                                logoScale = 1
                                logoOpacity = 1
                            }
                        }
                }
            }
            .navigationBarBackButtonHidden(true)   // 🚫 back button removed
            .navigationDestination(isPresented: $vm.goToStartPage) {
                StartPageView()
            }
            .onAppear {
                vm.startAnimation()
            }
        }
    }
}

#Preview {
    SplashPageView()
}

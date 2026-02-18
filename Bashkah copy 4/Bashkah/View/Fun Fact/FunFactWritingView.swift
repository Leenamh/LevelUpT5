import SwiftUI

struct FunFactWritingView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var navigateToJoker = false
    @State private var navigateToWaiting = false
    @State private var navigateToVoting = false   // ✅ new
    @State private var cardScale: CGFloat = 0.9
    @State private var buttonScale: CGFloat = 1.0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("Background"), Color("Background").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                roomNumberView

                Spacer().frame(height: 30)

                funFactCard

                Spacer()

                nextButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToJoker) {
            FunFactJokerCard(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $navigateToWaiting) {
            FunFactWaitingView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $navigateToVoting) {   // ✅ new
            FunFactVotingView(viewModel: viewModel)
        }
        .onAppear {
            // ✅ Ensure the phase listener exists
            viewModel.startRoomPhaseListenerIfNeeded()

            if let player = viewModel.currentPlayer {
                viewModel.currentPlayerFacts = player.facts
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
            }
        }
        // ✅ If voting starts while player is still here -> move
        .onChange(of: viewModel.shouldNavigateToVoting) { go in
            if go {
                navigateToVoting = true
            }
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()

            Button(action: {
                viewModel.showExitAlert = true
            }) {
                ZStack {
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .alert("خروج من الغرفة", isPresented: $viewModel.showExitAlert) {
            Button("إلغاء", role: .cancel) { }
            Button("خروج", role: .destructive) {
                viewModel.handleLeaveRoom()
                dismiss()
            }
        } message: {
            Text("هل أنت متأكد من الخروج من الغرفة؟")
        }
    }

    private var roomNumberView: some View {
        VStack(spacing: 8) {
            Text("رقم الغرفة")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            HStack(spacing: 10) {
                Text(viewModel.gameRoom?.roomNumber ?? "-----")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Button(action: {
                    UIPasteboard.general.string = viewModel.gameRoom?.roomNumber
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color("Orange").opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color("Orange"), Color("Orange").opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .padding(.top, -20)
    }

    private var funFactCard: some View {
        ZStack {
            Image("FactBack1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 360)
                .shadow(color: Color("Orange").opacity(0.3), radius: 15, x: 0, y: 10)

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                if !viewModel.currentPlayerFacts[viewModel.currentFactIndex].isEmpty {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("Orange"))
                        .padding(.bottom, 20)
                        .transition(.scale.combined(with: .opacity))
                }

                VStack {
                    Spacer()

                    TextField("اكتب الحقيقة",
                              text: $viewModel.currentPlayerFacts[viewModel.currentFactIndex],
                              axis: .vertical)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .lineLimit(8...12)
                        .tint(Color("Orange"))
                        .padding(.horizontal, 50)
                        // ✅ LOCK writing if voting has already started
                        .disabled(viewModel.phaseString == "voting")

                    Spacer()
                }
                .frame(height: 280)

                Spacer().frame(height: 20)

                Text("\(viewModel.currentFactIndex + 1)/5")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("Orange"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color("Orange").opacity(0.15)))

                Spacer().frame(height: 40)
            }
        }
        .scaleEffect(cardScale)
    }

    private var nextButton: some View {
        let hasText = !viewModel.currentPlayerFacts[viewModel.currentFactIndex]
            .trimmingCharacters(in: .whitespaces).isEmpty

        let locked = (viewModel.phaseString == "voting") // ✅

        return Button(action: {
            guard hasText, !locked else { return }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
                nextCard()
            }
        }) {
            ZStack {
                LinearGradient(
                    colors: (hasText && !locked) ? [
                        Color("Orange"),
                        Color("Orange").opacity(0.8)
                    ] : [
                        Color("Orange").opacity(0.4),
                        Color("Orange").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 56)
                .cornerRadius(28)
                .shadow(
                    color: (hasText && !locked) ? Color("Orange").opacity(0.5) : Color("Orange").opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )

                HStack(spacing: 8) {
                    Text(viewModel.currentFactIndex == 4 ? "إرسال" : "التالي")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    if viewModel.currentFactIndex < 4 {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .scaleEffect(buttonScale)
        .disabled(!hasText || locked)
        .padding(.bottom, 60)
    }

    private func nextCard() {
        if viewModel.currentFactIndex < 4 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 0.9
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.currentFactIndex += 1

                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    cardScale = 1.0
                }
            }
        } else {
            viewModel.submitFacts()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.isJoker {
                    navigateToJoker = true
                } else {
                    navigateToWaiting = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FunFactWritingView(viewModel: {
            let vm = FunFactViewModel()
            vm.createRoom(playerName: "حنين")
            return vm
        }())
    }
}

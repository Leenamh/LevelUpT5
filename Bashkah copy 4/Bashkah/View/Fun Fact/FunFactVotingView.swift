//
//  FunFactVotingView.swift
//  Bashkah - Fun Fact Game
//
//  Updated with 5-second timer and coins - 15/02/2026
//

import SwiftUI

struct FunFactVotingView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var navigateToWinners = false
    @State private var cardScale: CGFloat = 0.9
    @State private var totalFactsCount: Int = 0
    @State private var timeRemaining: Int = 5
    @State private var timerActive: Bool = false
    @State private var voteTimer: Timer? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("Background"),
                    Color("Orange").opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if timerActive && !viewModel.showingAnswer {
                    timerView
                }

                Spacer().frame(height: 15)
                funFactCardView

                if viewModel.showingAnswer {
                    answerSection
                }

                Spacer()

                if !viewModel.showingAnswer {
                    playerButtonsView
                }

                Spacer().frame(height: 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToWinners) {
            FunFactWinnersView(viewModel: viewModel)
        }

        // ✅ Trigger 1: phase -> results
        .onChange(of: viewModel.gameRoom?.currentPhase) { newPhase in
            guard let newPhase = newPhase else { return }

            if newPhase == .results {
                stopTimer()
                navigateToWinners = true
            } else if newPhase == .voting {
                resetTimer()
            }
        }

        // ✅ Trigger 2 (IMPORTANT): room status -> finished
        // Because your logs show "status: finished" happens even when phase doesn't.
        .onChange(of: viewModel.firebaseManager.currentRoom?.status) { newStatus in
            guard let newStatus = newStatus else { return }
            if newStatus == .finished {
                stopTimer()
                navigateToWinners = true
            }
        }

        // ✅ If host reveals answer, stop timer
        .onChange(of: viewModel.showingAnswer) { showing in
            if showing { stopTimer() }
        }

        // ✅ When fact changes, reset timer (if still voting)
        .onChange(of: viewModel.currentFactDocId) { _ in
            if viewModel.gameRoom?.currentPhase == .voting && !viewModel.showingAnswer {
                resetTimer()
            }
        }

        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
            }

            // ✅ Fallback: if the view appears after game already finished
            if viewModel.firebaseManager.currentRoom?.status == .finished {
                stopTimer()
                navigateToWinners = true
                return
            }

            if viewModel.currentDisplayFact == nil {
                viewModel.loadCurrentFact()
            }

            loadTotalFactsCount()
            resetTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.yellow)
                }

                Text("\(viewModel.currentPlayer?.score ?? 0)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            Button(action: {
                viewModel.showExitAlert = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .font(.system(size: 20, weight: .bold))
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

    // MARK: - Timer View
    private var timerView: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: CGFloat(timeRemaining) / 5.0)
                .stroke(
                    timeRemaining <= 2 ? Color.red : Color("Orange"),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 2) {
                Text("\(timeRemaining)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(timeRemaining <= 2 ? .red : Color("Orange"))

                Text("ثانية")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Timer Logic
    private func resetTimer() {
        stopTimer()
        timeRemaining = 5
        timerActive = true

        voteTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !timerActive || viewModel.showingAnswer {
                stopTimer()
                return
            }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                if viewModel.currentPlayer?.hasVoted == false && !viewModel.showingAnswer {
                    viewModel.handleTimeUp()
                }
            }
        }
    }

    private func stopTimer() {
        timerActive = false
        voteTimer?.invalidate()
        voteTimer = nil
    }

    // MARK: - Fun Fact Card View
    private var funFactCardView: some View {
        ZStack {
            Image("FactBack1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 360)
                .shadow(color: Color("Orange").opacity(0.3), radius: 15, x: 0, y: 10)

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                if let currentFact = viewModel.currentDisplayFact {
                    Text(currentFact.text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(height: 280)
                        .padding(.horizontal, 50)
                } else {
                    ProgressView()
                        .tint(Color("Orange"))
                        .frame(height: 280)
                }

                Spacer().frame(height: 20)

                if let room = viewModel.gameRoom {
                    Text("\(room.currentFactIndex + 1) / \(totalFactsCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.8)))
                }

                Spacer().frame(height: 50)
            }
        }
        .scaleEffect(cardScale)
    }

    private func loadTotalFactsCount() {
        guard let roomId = viewModel.firebaseManager.currentRoom?.roomId else { return }

        viewModel.firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("facts")
            .getDocuments { snapshot, _ in
                if let count = snapshot?.documents.count {
                    DispatchQueue.main.async {
                        self.totalFactsCount = count
                    }
                }
            }
    }

    // MARK: - Answer Section
    private var answerSection: some View {
        VStack(spacing: 15) {
            if let currentFact = viewModel.currentDisplayFact {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("الإجابة الصحيحة:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Text(currentFact.playerName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color("Orange"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
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
                .padding(.horizontal, 40)

                if let selectedVote = viewModel.selectedVote,
                   selectedVote.uuidString == (viewModel.currentFactPlayerId ?? "") {
                    HStack(spacing: 8) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)

                        Text("+1 عملة")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.1)))
                    .transition(.scale.combined(with: .opacity))
                } else if viewModel.currentPlayer?.hasVoted == true {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)

                        Text("إجابة خاطئة")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.red.opacity(0.1)))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Player Buttons View
    private var playerButtonsView: some View {
        let players = viewModel.firebaseManager.connectedPlayers
        let correctPlayerId = viewModel.currentFactPlayerId ?? ""

        return VStack(spacing: 12) {
            ForEach(0..<(players.count + 1) / 2, id: \.self) { row in
                HStack(spacing: 12) {
                    let startIndex = row * 2

                    if startIndex < players.count {
                        AnimatedVoteButton(
                            playerName: players[startIndex].name,
                            playerId: players[startIndex].id,
                            isSelected: viewModel.selectedVote?.uuidString == players[startIndex].id,
                            isCorrect: correctPlayerId == players[startIndex].id,
                            showAnswer: viewModel.showingAnswer,
                            canVote: viewModel.currentPlayer?.hasVoted == false && timeRemaining > 0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if let uuid = UUID(uuidString: players[startIndex].id) {
                                    viewModel.submitVote(chosenPlayerID: uuid)
                                    stopTimer()
                                }
                            }
                        }
                    }

                    if startIndex + 1 < players.count {
                        AnimatedVoteButton(
                            playerName: players[startIndex + 1].name,
                            playerId: players[startIndex + 1].id,
                            isSelected: viewModel.selectedVote?.uuidString == players[startIndex + 1].id,
                            isCorrect: correctPlayerId == players[startIndex + 1].id,
                            showAnswer: viewModel.showingAnswer,
                            canVote: viewModel.currentPlayer?.hasVoted == false && timeRemaining > 0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if let uuid = UUID(uuidString: players[startIndex + 1].id) {
                                    viewModel.submitVote(chosenPlayerID: uuid)
                                    stopTimer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Animated Vote Button
struct AnimatedVoteButton: View {
    let playerName: String
    let playerId: String
    let isSelected: Bool
    let isCorrect: Bool
    let showAnswer: Bool
    let canVote: Bool
    let action: () -> Void

    @State private var scale: CGFloat = 1.0

    var buttonGradient: LinearGradient {
        if showAnswer && isCorrect {
            return LinearGradient(
                colors: [Color("Orange"), Color("Orange").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isSelected && !showAnswer {
            return LinearGradient(
                colors: [Color("Orange").opacity(0.7), Color("Orange").opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if !showAnswer {
            return LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        Button(action: {
            if canVote && !showAnswer {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.0
                    }
                    action()
                }
            }
        }) {
            HStack(spacing: 8) {
                Text(playerName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                if showAnswer && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
            }
            .frame(width: 160, height: 52)
            .background(buttonGradient)
            .cornerRadius(26)
            .shadow(
                color: (showAnswer && isCorrect ? Color("Orange") : Color.gray).opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .scaleEffect(scale)
        .disabled(!canVote || showAnswer)
    }
}

#Preview {
    NavigationStack {
        FunFactVotingView(viewModel: {
            let vm = FunFactViewModel()
            vm.currentPlayer = FunFactPlayer(name: "حنين", deviceID: "test", isHost: true)
            vm.gameRoom = FunFactRoom(roomNumber: "12345", players: [], hostDeviceID: "test")
            return vm
        }())
    }
}

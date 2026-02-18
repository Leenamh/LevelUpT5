//
//  FunFactWinnersView.swift
//  Bashkah - Fun Fact Game
//
//  صفحة النتائج النهائية - عرض الفائزين
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct FunFactWinnersView: View {
    @ObservedObject var viewModel: FunFactViewModel

    @State private var showMedals = false
    @State private var buttonScale1: CGFloat = 1.0
    @State private var buttonScale2: CGFloat = 1.0
    @State private var showPodium = false
    @State private var currentAnnouncingPosition: Int? = nil
    @State private var showWinnerOnPodium: [Int: Bool] = [:]
    @State private var showButtons = false

    // ✅ NEW
    @State private var isLoadingResults: Bool = true
    @State private var didStartAnimation: Bool = false

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
                titleView
                Spacer().frame(height: 40)

                ZStack {
                    if isLoadingResults {
                        loadingView
                    } else if viewModel.finalResults.isEmpty {
                        emptyResultsView
                    } else {
                        winnersView

                        if let position = currentAnnouncingPosition,
                           let winner = getWinner(for: position) {
                            WinnerAnnouncementView(
                                winner: winner,
                                position: position,
                                medal: getMedalName(for: position)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                Spacer()

                if !isLoadingResults && !viewModel.finalResults.isEmpty {
                    actionButtons
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadFinalResultsIfNeeded()
        }
    }

    // MARK: - Load Results (✅ FIX)
    private func loadFinalResultsIfNeeded() {
        // If already computed, just animate
        if !viewModel.finalResults.isEmpty {
            isLoadingResults = false
            startAnimationIfNeeded()
            return
        }

        guard let roomId = viewModel.firebaseManager.currentRoom?.roomId else {
            isLoadingResults = false
            return
        }

        isLoadingResults = true

        viewModel.firebaseManager.db.collection("gameRooms")
            .document(roomId)
            .collection("players")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingResults = false

                    if let error = error {
                        print("❌ Error fetching winners: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else { return }

                    // Build scores from Firestore
                    var scores: [PlayerScore] = []

                    for doc in docs {
                        let data = doc.data()
                        let playerIdStr = doc.documentID
                        let name = (data["name"] as? String) ?? "Player"
                        let score = (data["score"] as? Int) ?? 0

                        let playerUuid = UUID(uuidString: playerIdStr) ?? UUID()

                        scores.append(
                            PlayerScore(
                                playerID: playerUuid,
                                playerName: name,
                                score: score,
                                rank: 0
                            )
                        )
                    }

                    // Sort desc
                    scores.sort { $0.score > $1.score }

                    // Assign ranks
                    for i in 0..<scores.count {
                        scores[i] = PlayerScore(
                            playerID: scores[i].playerID,
                            playerName: scores[i].playerName,
                            score: scores[i].score,
                            rank: i + 1
                        )
                    }

                    // Keep top 3 for podium (your view expects index 0..2)
                    self.viewModel.finalResults = Array(scores.prefix(3))

                    self.startAnimationIfNeeded()
                }
            }
    }

    private func startAnimationIfNeeded() {
        guard !didStartAnimation else { return }
        didStartAnimation = true
        resetAnimations()
        startAnimationSequence()
    }

    private func resetAnimations() {
        showMedals = false
        showPodium = false
        currentAnnouncingPosition = nil
        showWinnerOnPodium = [:]
        showButtons = false
    }

    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            showPodium = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            announceWinner(position: 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            announceWinner(position: 2)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            announceWinner(position: 1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showButtons = true
            }
        }
    }

    private func announceWinner(position: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentAnnouncingPosition = position
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                currentAnnouncingPosition = nil
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showWinnerOnPodium[position] = true
                    showMedals = true
                }

                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
        }
    }

    private func getWinner(for position: Int) -> PlayerScore? {
        guard position >= 1 && position <= 3,
              viewModel.finalResults.count >= position else {
            return nil
        }
        return viewModel.finalResults[position - 1]
    }

    private func getMedalName(for position: Int) -> String {
        switch position {
        case 1: return "gold"
        case 2: return "selver" // keep your asset name as-is
        case 3: return "plat"   // keep your asset name as-is
        default: return "gold"
        }
    }

    // MARK: - Title View
    private var titleView: some View {
        Text("الفائزين")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.black)
            .padding(.top, 20)
    }

    // MARK: - Loading / Empty
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color("Orange"))
                .scaleEffect(1.3)

            Text("جاري تحميل النتائج...")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }

    private var emptyResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundColor(.orange)

            Text("لا توجد نتائج للعرض")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }

    // MARK: - Winners View (Top 3)
    private var winnersView: some View {
        VStack(spacing: 30) {
            podiumView
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Podium View
    private var podiumView: some View {
        VStack(spacing: 30) {
            if viewModel.finalResults.count > 0 {
                WinnerMedal(
                    ranking: viewModel.finalResults[0],
                    medal: "gold",
                    appeared: showMedals && showWinnerOnPodium[1] == true
                )
                .opacity(showPodium ? 1.0 : 0.0)
            }

            HStack(spacing: 40) {
                if viewModel.finalResults.count > 1 {
                    WinnerMedal(
                        ranking: viewModel.finalResults[1],
                        medal: "selver",
                        appeared: showMedals && showWinnerOnPodium[2] == true,
                        isSmaller: true
                    )
                    .opacity(showPodium ? 1.0 : 0.0)
                }

                if viewModel.finalResults.count > 2 {
                    WinnerMedal(
                        ranking: viewModel.finalResults[2],
                        medal: "plat",
                        appeared: showMedals && showWinnerOnPodium[3] == true,
                        isSmaller: true
                    )
                    .opacity(showPodium ? 1.0 : 0.0)
                }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 18) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale1 = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale1 = 1.0
                    }
                    viewModel.leaveRoom()
                    dismiss()
                }
            }) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("Orange"),
                            Color("Orange").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 320, height: 58)
                    .cornerRadius(29)
                    .shadow(color: Color("Orange").opacity(0.5), radius: 15, x: 0, y: 8)

                    Text("العب مرة أخرى")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(buttonScale1)
            .opacity(showButtons ? 1.0 : 0.0)
            .scaleEffect(showButtons ? 1.0 : 0.8)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale2 = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale2 = 1.0
                    }
                    viewModel.leaveRoom()
                    dismiss()
                }
            }) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("Orange"),
                            Color("Orange").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 320, height: 58)
                    .cornerRadius(29)
                    .shadow(color: Color("Orange").opacity(0.5), radius: 15, x: 0, y: 8)

                    Text("الخروج من الغرفة")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(buttonScale2)
            .opacity(showButtons ? 1.0 : 0.0)
            .scaleEffect(showButtons ? 1.0 : 0.8)
        }
        .padding(.bottom, 60)
    }
}

// MARK: - Winner Medal
struct WinnerMedal: View {
    let ranking: PlayerScore
    let medal: String
    let appeared: Bool
    var isSmaller: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Image(medal)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isSmaller ? 80 : 120, height: isSmaller ? 80 : 120)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1.0 : 0.0)

            Text(ranking.playerName)
                .font(.system(size: isSmaller ? 18 : 22, weight: .bold))
                .foregroundColor(.black)
                .opacity(appeared ? 1.0 : 0.0)
        }
    }
}

// MARK: - Winner Announcement View
struct WinnerAnnouncementView: View {
    let winner: PlayerScore
    let position: Int
    let medal: String

    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -10

    var body: some View {
        VStack(spacing: 30) {
            Text(positionText)
                .font(.system(size: 50, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [positionColor, positionColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: positionColor.opacity(0.5), radius: 15)
                .scaleEffect(scale)

            Image(medal)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .shadow(color: positionColor.opacity(0.5), radius: 20)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))

            Text(winner.playerName)
                .font(.system(size: 45, weight: .heavy))
                .foregroundColor(.black)
                .shadow(color: positionColor.opacity(0.3), radius: 5)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.2
                rotation = 0
            }

            withAnimation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.4)) {
                scale = 1.0
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private var positionText: String {
        switch position {
        case 1: return "المركز الأول"
        case 2: return "المركز الثاني"
        case 3: return "المركز الثالث"
        default: return ""
        }
    }

    private var positionColor: Color {
        switch position {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.brown
        default: return Color.gray
        }
    }
}


#Preview {
    NavigationStack {
        FunFactWinnersView(viewModel: {
            let vm = FunFactViewModel()
            vm.finalResults = [
                PlayerScore(playerID: UUID(), playerName: "حصة", score: 500, rank: 1),
                PlayerScore(playerID: UUID(), playerName: "نورة", score: 400, rank: 2),
                PlayerScore(playerID: UUID(), playerName: "هيا", score: 300, rank: 3)
            ]
            return vm
        }())
    }
}

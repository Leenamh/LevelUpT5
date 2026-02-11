//
//  FunFactWinnersView.swift
//  Bashkah - Fun Fact Game
//
//  صفحة النتائج النهائية - عرض الفائزين
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactWinnersView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var showMedals = false
    @State private var buttonScale1: CGFloat = 1.0
    @State private var buttonScale2: CGFloat = 1.0
    @State private var showPodium = false
    @State private var currentAnnouncingPosition: Int? = nil
    @State private var showWinnerOnPodium: [Int: Bool] = [:]
    @State private var showButtons = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
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
                // Title
                titleView
                
                Spacer()
                    .frame(height: 40)
                
                // Top 3 Winners with medals
                ZStack {
                    winnersView
                    
                    // إعلان الفائز في النص
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
                
                Spacer()
                
                // Action Buttons
                actionButtons
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        // 1. إظهار المنصة فاضية
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            showPodium = true
        }
        
        // 2. إعلان المركز الثالث
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            announceWinner(position: 3)
        }
        
        // 3. إعلان المركز الثاني
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            announceWinner(position: 2)
        }
        
        // 4. إعلان المركز الأول
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            announceWinner(position: 1)
        }
        
        // 5. إظهار الأزرار
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showButtons = true
            }
        }
    }
    
    private func announceWinner(position: Int) {
        // إظهار الإعلان في النص
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentAnnouncingPosition = position
        }
        
        // بعد ثانية ونص، إخفاء الإعلان وإظهار الفائز على المنصة
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                currentAnnouncingPosition = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showWinnerOnPodium[position] = true
                    showMedals = true
                }
                
                // Haptic feedback
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
        case 2: return "selver"
        case 3: return "plat"
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
    
    // MARK: - Winners View (Top 3)
    private var winnersView: some View {
        VStack(spacing: 30) {
            // Podium Structure
            podiumView
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Podium View
    private var podiumView: some View {
        VStack(spacing: 30) {
            // First Place
            if viewModel.finalResults.count > 0 {
                WinnerMedal(
                    ranking: viewModel.finalResults[0],
                    medal: "gold",
                    appeared: showMedals && showWinnerOnPodium[1] == true
                )
                .opacity(showPodium ? 1.0 : 0.0)
            }
            
            // Second and Third
            HStack(spacing: 40) {
                // Second Place
                if viewModel.finalResults.count > 1 {
                    WinnerMedal(
                        ranking: viewModel.finalResults[1],
                        medal: "selver",
                        appeared: showMedals && showWinnerOnPodium[2] == true,
                        isSmaller: true
                    )
                    .opacity(showPodium ? 1.0 : 0.0)
                }
                
                // Third Place
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
            // Play Again Button
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
            
            // Exit Button
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
            // Medal Image
            Image(medal)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isSmaller ? 80 : 120, height: isSmaller ? 80 : 120)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1.0 : 0.0)
            
            // Player Name
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
            // المركز أولاً
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
            
            // الميدالية (الصورة)
            Image(medal)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .shadow(color: positionColor.opacity(0.5), radius: 20)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
            
            // اسم الفائز
            Text(winner.playerName)
                .font(.system(size: 45, weight: .heavy))
                .foregroundColor(.black)
                .shadow(color: positionColor.opacity(0.3), radius: 5)
                .scaleEffect(scale)
        }
        .onAppear {
            // أنيميشن الظهور - أبطأ
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.2
                rotation = 0
            }
            
            withAnimation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.4)) {
                scale = 1.0
            }
            
            // Haptic feedback
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

//
//  FunFactVotingView.swift
//  Bashkah - Fun Fact Game
//
//  صفحة التصويت - عرض الحقيقة والتصويت
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactVotingView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var navigateToWinners = false
    @State private var cardScale: CGFloat = 0.9
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
                // Header
                headerView
                
                Spacer()
                    .frame(height: 25)
                
                // Fun Fact Card
                funFactCardView
                
                // Answer Section (if showing answer)
                if viewModel.showingAnswer {
                    answerSection
                }
                
                Spacer()
                
                // Player Buttons
                playerButtonsView
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToWinners) {
            FunFactWinnersView(viewModel: viewModel)
        }
        .onChange(of: viewModel.gameRoom?.currentPhase) { newPhase in
            if newPhase == .results {
                navigateToWinners = true
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Score Display with icon
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.yellow)
                }
                
                Text("\(viewModel.currentPlayer?.score ?? 0)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Exit button
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("Orange").opacity(0.3), Color("Orange").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 20, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Fun Fact Card View
    private var funFactCardView: some View {
        ZStack {
            // Card Background
            Image("FactBack")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 360)
                .shadow(color: Color("Orange").opacity(0.3), radius: 15, x: 0, y: 10)
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)
                
                // Fact Text
                if let currentFact = viewModel.gameRoom?.currentFact {
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
                
                Spacer()
                    .frame(height: 20)
                
                // Card Counter
                if let room = viewModel.gameRoom {
                    Text("\(room.currentFactIndex + 1) / \(room.allFacts.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                        )
                }
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .scaleEffect(cardScale)
    }
    
    // MARK: - Answer Section
    private var answerSection: some View {
        VStack(spacing: 10) {
            if let currentFact = viewModel.gameRoom?.currentFact {
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
                .padding(.top, 15)
            }
        }
    }
    
    // MARK: - Player Buttons View
    private var playerButtonsView: some View {
        let players = viewModel.gameRoom?.players ?? []
        let currentFact = viewModel.gameRoom?.currentFact
        
        return VStack(spacing: 12) {
            ForEach(0..<(players.count + 1) / 2, id: \.self) { row in
                HStack(spacing: 12) {
                    let startIndex = row * 2
                    
                    if startIndex < players.count {
                        AnimatedVoteButton(
                            player: players[startIndex],
                            isSelected: viewModel.selectedVote == players[startIndex].id,
                            isCorrect: currentFact?.playerID == players[startIndex].id,
                            showAnswer: viewModel.showingAnswer,
                            canVote: viewModel.currentPlayer?.hasVoted == false
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.submitVote(chosenPlayerID: players[startIndex].id)
                            }
                        }
                    }
                    
                    if startIndex + 1 < players.count {
                        AnimatedVoteButton(
                            player: players[startIndex + 1],
                            isSelected: viewModel.selectedVote == players[startIndex + 1].id,
                            isCorrect: currentFact?.playerID == players[startIndex + 1].id,
                            showAnswer: viewModel.showingAnswer,
                            canVote: viewModel.currentPlayer?.hasVoted == false
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.submitVote(chosenPlayerID: players[startIndex + 1].id)
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
    let player: FunFactPlayer
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
                Text(player.name)
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
            vm.createRoom(playerName: "حنين")
            
            if var room = vm.gameRoom {
                let player2 = FunFactPlayer(name: "نجد", deviceID: "device2", isReady: true)
                let player3 = FunFactPlayer(name: "لينا", deviceID: "device3", isReady: true)
                let player4 = FunFactPlayer(name: "حصة", deviceID: "device4", isReady: true)
                let player5 = FunFactPlayer(name: "ميسم", deviceID: "device5", isReady: true)
                
                room.players.append(contentsOf: [player2, player3, player4, player5])
                
                let fact = FunFact(playerID: room.players[0].id, playerName: room.players[0].name, text: "احب القهوة\nعادي كل اليوم\nبس اشرب قهوه")
                room.allFacts = [fact]
                room.currentPhase = .voting
                
                vm.gameRoom = room
            }
            
            return vm
        }())
    }
}

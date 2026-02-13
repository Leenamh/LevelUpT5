//
//  FunFactOpinion.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  FunFactOpinion.swift
//  Bashkah - Fun Fact Game
//
//  غرفة الانتظار - عرض كل اللاعبين
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactOpinion: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var navigateToVoting = false
    @State private var showExitAlert = false
    @State private var cardsAppeared = false
    @State private var pulseAnimation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Animated background
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
            }
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Title with glow - no spacer, directly after header
                titleView
                
                // Player Count with pulse
                playerCountView
                
                Spacer()
                    .frame(height: 35)
                
                // Players in circle layout
                playersCircle
                
                Spacer()
                
                // Start Button (Host only)
                if viewModel.isHost {
                    startButton
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToVoting) {
            FunFactVotingView(viewModel: viewModel)
        }
        .alert("خروج من الغرفة", isPresented: $showExitAlert) {
            Button("إلغاء", role: .cancel) { }
            Button("خروج", role: .destructive) {
                viewModel.leaveRoom()
                dismiss()
            }
        } message: {
            Text("هل أنت متأكد من الخروج من الغرفة؟")
        }
        .onChange(of: viewModel.gameRoom?.currentPhase) { newPhase in
            if newPhase == .voting {
                navigateToVoting = true
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                cardsAppeared = true
            }
            startPulse()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                showExitAlert = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.25), Color.red.opacity(0.1)],
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
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Title
    private var titleView: some View {
        VStack(spacing: 10) {
            Text("بانتظار اللاعبين")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.top, -40) // رفعها فوق مستوى زر الخروج
    }
    
    // MARK: - Player Count
    private var playerCountView: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundColor(Color("Orange"))
            
            Text("\(viewModel.gameRoom?.players.count ?? 0)/6 لاعبين")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color("Orange"))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color("Orange").opacity(0.15))
        )
        .scaleEffect(pulseAnimation ? 1.08 : 1.0)
        .padding(.top, 20)
    }
    
    // MARK: - Players Circle
    private var playersCircle: some View {
        let players = viewModel.gameRoom?.players ?? []
        
        return ZStack {
            // Players positioned in circle
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                PlayerCardCircular(player: player, appeared: cardsAppeared)
                    .offset(
                        x: cos(angleForIndex(index, total: players.count)) * 120,
                        y: sin(angleForIndex(index, total: players.count)) * 120
                    )
            }
        }
        .frame(height: 450)
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            viewModel.startGame()
        }) {
            ZStack {
                LinearGradient(
                    colors: viewModel.canStartGame ? [
                        Color("Orange"),
                        Color("Orange").opacity(0.8)
                    ] : [
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 180, height: 56)
                .cornerRadius(28)
                .shadow(
                    color: viewModel.canStartGame ? Color("Orange").opacity(0.5) : Color.gray.opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                HStack(spacing: 10) {
               
                    
                    Text("ابدأ")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!viewModel.canStartGame)
        .scaleEffect(viewModel.canStartGame && pulseAnimation ? 1.05 : 1.0)
        .padding(.bottom, 60)
    }
    
    // MARK: - Helper Functions
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = (2 * .pi) / Double(total)
        return angleStep * Double(index) - .pi / 2
    }
    
    private func startPulse() {
        withAnimation(
            Animation.easeInOut(duration: 1.3)
                .repeatForever(autoreverses: true)
        ) {
            pulseAnimation = true
        }
    }
}

// MARK: - Player Card Circular
struct PlayerCardCircular: View {
    let player: FunFactPlayer
    let appeared: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                // Card with animation
                Image("FunFact")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 75, height: 75)
                    .shadow(color: Color("Orange").opacity(0.35), radius: 10, x: 0, y: 6)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0.0)
                
                // Ready indicator
                if player.isReady {
                    Circle()
                        .fill(Color("Green"))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: 4)
                        .scaleEffect(appeared ? 1.0 : 0.0)
                }
            }
            
            // Player name
            Text(player.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                )
                .opacity(appeared ? 1.0 : 0.0)
        }
    }
}



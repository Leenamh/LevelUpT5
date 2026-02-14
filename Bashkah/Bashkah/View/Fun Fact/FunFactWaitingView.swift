//
//  FunFactWaitingView.swift
//  Bashkah - Fun Fact Game
//
//  FIXED - With real-time auto-start - 15/02/2026
//

import SwiftUI

struct FunFactWaitingView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var pulseAnimation = false
    @State private var navigateToVoting = false
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated hourglass icon
                Image(systemName: "hourglass")
                    .font(.system(size: 80))
                    .foregroundColor(Color("Orange"))
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .rotationEffect(.degrees(pulseAnimation ? 180 : 0))
                
                // Message
                VStack(spacing: 12) {
                    Text("انتظر قليلاً")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("بانتظار اللاعبين الآخرين\nلإكمال حقائقهم")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Players progress
                playersProgressView
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("Orange"))
                
                // 🔧 FIX: Manual start button for host (backup)
                if viewModel.isHost && allPlayersReady {
                    Button(action: {
                        print("🎯 Manual start triggered by host")
                        viewModel.manualStartVoting()
                    }) {
                        Text("ابدأ اللعبة")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color("Orange"), Color("Orange").opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToVoting) {
            FunFactVotingView(viewModel: viewModel)
        }
        .onAppear {
            startAnimations()
            
            // Start listening for game phase changes
            viewModel.setupWaitingListener { shouldNavigate in
                if shouldNavigate {
                    navigateToVoting = true
                }
            }
        }
    }
    
    // MARK: - Players Progress View
    private var playersProgressView: some View {
        VStack(spacing: 16) {
            Text("تقدم اللاعبين")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(viewModel.firebaseManager.connectedPlayers, id: \.id) { player in
                    HStack(spacing: 12) {
                        // Player name
                        Text(player.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 100, alignment: .leading)
                        
                        // Progress indicator
                        if player.isReady {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("جاهز")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("يكتب...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Check if all players ready
    private var allPlayersReady: Bool {
        let players = viewModel.firebaseManager.connectedPlayers
        guard !players.isEmpty else { return false }
        return players.allSatisfy { $0.isReady }
    }
    
    // MARK: - Start Animations
    private func startAnimations() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseAnimation = true
        }
    }
}

#Preview {
    NavigationStack {
        FunFactWaitingView(viewModel: {
            let vm = FunFactViewModel()
            return vm
        }())
    }
}

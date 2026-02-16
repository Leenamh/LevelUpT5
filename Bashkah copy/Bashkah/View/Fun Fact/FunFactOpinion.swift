//
//  FunFactOpinion.swift
//  Bashkah
//
//  Migrated to Firebase with MVVM - 14/02/2026
//

import SwiftUI

struct FunFactOpinion: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var cardsAppeared = false
    @State private var pulseAnimation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundView
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Title
                titleView
                
                // Room Number Display
                roomNumberView
                
                // Player Count
                playerCountView
                
                Spacer()
                    .frame(height: 35)
                
                // Players in circle layout
                playersCircle
                
                Spacer()
                
                // Start Writing Button (Host only)
                if viewModel.isHost {
                    startWritingButton
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $viewModel.navigateToWriting) {
            FunFactWritingView(viewModel: viewModel)
        }
        .alert("خروج من الغرفة", isPresented: $viewModel.showExitAlert) {
            Button("إلغاء", role: .cancel) { }
            Button("خروج", role: .destructive) {
                viewModel.handleLeaveRoom()
                dismiss()
            }
        } message: {
            Text("هل أنت متأكد من الخروج من الغرفة؟")
        }
        .onAppear {
            viewModel.setupRoomLobby()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                cardsAppeared = true
            }
            startPulse()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                viewModel.showExitAlert = true
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
        .padding(.top, -40)
    }
    
    // MARK: - Room Number
    private var roomNumberView: some View {
        VStack(spacing: 8) {
            Text("رقم الغرفة")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Text(viewModel.roomNumber)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color("Orange"))
                    .tracking(4)
                
                Button(action: {
                    viewModel.copyRoomNumber()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color("Orange").opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Player Count
    private var playerCountView: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundColor(Color("Orange"))
            
            Text("\(viewModel.playerCount)/8 لاعبين")
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
        .padding(.top, 16)
    }
    
    // MARK: - Players Circle
    private var playersCircle: some View {
        ZStack {
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                PlayerCardCircular(
                    player: player,
                    appeared: cardsAppeared
                )
                .offset(
                    x: cos(viewModel.angleForPlayer(at: index)) * 120,
                    y: sin(viewModel.angleForPlayer(at: index)) * 120
                )
            }
        }
        .frame(height: 450)
    }
    
    // MARK: - Start Writing Button
    private var startWritingButton: some View {
        Button(action: {
            viewModel.startWritingPhase()
        }) {
            ZStack {
                LinearGradient(
                    colors: viewModel.canStartWriting ? [
                        Color("Orange"),
                        Color("Orange").opacity(0.8)
                    ] : [
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 220, height: 56)
                .cornerRadius(28)
                .shadow(
                    color: viewModel.canStartWriting ? Color("Orange").opacity(0.5) : Color.gray.opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("ابدأ الكتابة")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .disabled(!viewModel.canStartWriting || viewModel.isLoading)
        .scaleEffect(viewModel.canStartWriting && pulseAnimation ? 1.05 : 1.0)
        .padding(.bottom, 60)
    }
    
    // MARK: - Animations
    private func startPulse() {
        withAnimation(
            Animation.easeInOut(duration: 1.3)
                .repeatForever(autoreverses: true)
        ) {
            pulseAnimation = true
        }
    }
}

// MARK: - Player Card Component
struct PlayerCardCircular: View {
    let player: GamePlayer
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
                
                // Host indicator
                if player.isHost {
                    Circle()
                        .fill(Color("Orange"))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: -60)
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

#Preview {
    NavigationStack {
        FunFactOpinion(viewModel: {
            let vm = FunFactViewModel()
            vm.currentPlayer = FunFactPlayer(name: "حنين", deviceID: "test", isHost: true)
            vm.gameRoom = FunFactRoom(roomNumber: "12345", players: [], hostDeviceID: "test")
            return vm
        }())
    }
}

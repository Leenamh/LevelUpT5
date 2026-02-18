//
//  TrendingTopicLobbyView.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  TrendingTopicLobbyView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicLobbyView: View {
    @StateObject var vm: TrendingTopicLobbyVM
    @Environment(\.dismiss) private var dismiss
    @State private var cardsAppeared = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    Color("Background"),
                    Color("DarkBlue").opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Title
                titleView
                
                // Player Count with pulse
                playerCountView
                
                Spacer()
                    .frame(height: 35)
                
                // Players in circle layout
                playersCircle
                
                Spacer()
                
                // Start Button (Host only)
                if vm.isHost {
                    startButton
                }
            }
        }
        .navigationBarBackButtonHidden(true)
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
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("DarkBlue").opacity(0.25), Color("DarkBlue").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color("DarkBlue"))
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
    
    // MARK: - Player Count
    private var playerCountView: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundColor(Color("DarkBlue"))
            
            Text("\(vm.room.players.count)/6 لاعبين")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color("DarkBlue"))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color("DarkBlue").opacity(0.15))
        )
        .scaleEffect(pulseAnimation ? 1.08 : 1.0)
        .padding(.top, 20)
    }
    
    // MARK: - Players Circle
    private var playersCircle: some View {
        let players = vm.room.players
        
        return ZStack {
            // Players positioned in circle
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                TTPlayerCardCircular(player: player, appeared: cardsAppeared, rotation: rotationForIndex(index))
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
        NavigationLink(value: AppRoute.trendingGame) {
            ZStack {
                LinearGradient(
                    colors: vm.isHost ? [
                        Color("DarkBlue"),
                        Color("DarkBlue").opacity(0.8)
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
                    color: vm.isHost ? Color("DarkBlue").opacity(0.5) : Color.gray.opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                Text("ابدأ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .disabled(!vm.isHost)
        .scaleEffect(vm.isHost && pulseAnimation ? 1.05 : 1.0)
        .padding(.bottom, 60)
    }
    
    // MARK: - Helper Functions
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = (2 * .pi) / Double(total)
        return angleStep * Double(index) - .pi / 2
    }
    
    private func rotationForIndex(_ index: Int) -> Double {
        // Create different tilts for each position
        let tilts = [-12.0, 8.0, -15.0, 10.0, -8.0, 12.0, -10.0, 15.0]
        return tilts[index % tilts.count]
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

// MARK: - Player Card Circular for Trending Topic
struct TTPlayerCardCircular: View {
    let player: TTPlayer
    let appeared: Bool
    let rotation: Double
    
    var body: some View {
        VStack(spacing: 6) {
            // Card with animation
            Image("TrendingTopicsFront")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color("DarkBlue").opacity(0.35), radius: 10, x: 0, y: 6)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1.0 : 0.0)
            
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
        TrendingTopicLobbyView(
            vm: TrendingTopicLobbyVM(
                room: TTRoom(
                    code: "12345",
                    players: [
                        TTPlayer(name: "حصة"),
                        TTPlayer(name: "حنين"),
                        TTPlayer(name: "لينا"),
                        TTPlayer(name: "نورة"),
                        TTPlayer(name: "سارة"),
                        TTPlayer(name: "مها")
                    ]
                ),
                isHost: true
            )
        )
    }
}

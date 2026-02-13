//
//  UnpopularOpinionStartView.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  UnpopularOpinionStartView.swift
//  Bashkah
//
//  Created on 24/08/1447 AH.
//

import SwiftUI

struct UnpopularOpinionStartView: View {
    @AppStorage("playerName") private var playerName: String = ""
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = -5
    @State private var buttonScale1: CGFloat = 1.0
    @State private var buttonScale2: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [Color("Background"), Color("Background").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back Button
                backButton
                
                Spacer()
                
                // Logo with animation
                logoView
                
                Spacer()
                    .frame(height: 150)
                
                // Buttons
                actionButtons
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: AppRoute.self) { route in
            routeDestination(for: route)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        HStack {
            Spacer()
            
            NavigationLink(value: AppRoute.unpopularStart) {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "56805D").opacity(0.3), Color(hex: "56805D").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    
                    Image(systemName: "chevron.forward")
                        .foregroundColor(Color(hex: "56805D"))
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        Image("unpopularOpinionPage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color(hex: "56805D").opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 18) {
            // Create New Game Button
            NavigationLink(value: AppRoute.unpopularWriting(
                roomCode: String(format: "%05d", Int.random(in: 10000...99999)),
                isHost: true
            )) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "56805D"),
                            Color(hex: "56805D").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 320, height: 58)
                    .cornerRadius(29)
                    .shadow(color: Color(hex: "56805D").opacity(0.5), radius: 15, x: 0, y: 8)
                    
                    Text("ابدأ لعبة جديدة")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale1 = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale1 = 1.0
                    }
                }
            })
            .scaleEffect(buttonScale1)
            
            // Join Game Button
            NavigationLink(value: AppRoute.unpopularJoin) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "56805D"),
                            Color(hex: "56805D").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 320, height: 58)
                    .cornerRadius(29)
                    .shadow(color: Color(hex: "56805D").opacity(0.5), radius: 15, x: 0, y: 8)
                    
                    Text("دخول لعبة")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale2 = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale2 = 1.0
                    }
                }
            })
            .scaleEffect(buttonScale2)
        }
    }
    
    // MARK: - Route Destination
    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .unpopularJoin:
            UnpopularOpinionJoinView(vm: UnpopularOpinionJoinVM(displayName: playerName))
        case .unpopularWriting(let roomCode, let isHost):
            UnpopularOpinionWritingView(
                vm: UnpopularOpinionWritingVM(roomCode: roomCode, playerName: playerName, isHost: isHost)
            )
        case .unpopularLobby(let room, let isHost):
            UnpopularOpinionLobbyView(vm: UnpopularOpinionLobbyVM(room: room, isHost: isHost))
        case .unpopularVoting(let room, let playerID):
            UnpopularOpinionVotingView(vm: UnpopularOpinionVotingVM(room: room, currentPlayerID: playerID))
        case .unpopularResults(let room):
            UnpopularOpinionResultsView(vm: UnpopularOpinionResultsVM(room: room))
        default:
            EmptyView()
        }
    }
    
    // MARK: - Start Animations
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoRotation = 0
        }
        
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            logoScale = 1.05
        }
        
        withAnimation(
            Animation.easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            logoRotation = 2
        }
    }
}

#Preview {
    NavigationStack {
        UnpopularOpinionStartView()
    }
}

//
//  FunFactStartPage.swift
//  Bashkah - Fun Fact Game
//
//  صفحة البداية للعبة هات العلم
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactStartPage: View {
    @StateObject private var viewModel = FunFactViewModel()
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
                    .frame(height: 80)
                
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
            // Set player name from UserDefaults
            if !playerName.isEmpty {
                viewModel.currentPlayer = FunFactPlayer(
                    name: playerName,
                    deviceID: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                )
            }
            startAnimations()
        }
    }
    
    // MARK: - Route Destination
    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .funFactWriting:
            FunFactWritingView(viewModel: viewModel)
        case .funFactJoin:
            FunFactJoinRoom(viewModel: viewModel)
        default:
            EmptyView()
        }
    }
    
    // MARK: - Back Button with gradient
    private var backButton: some View {
        HStack {
            Spacer()
            
            NavigationLink(value: AppRoute.funFactStart) {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [Color("Orange").opacity(0.3), Color("Orange").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Logo View with animation
    private var logoView: some View {
        Image("funFact 1")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color("Orange").opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Action Buttons with gradient and animation
    private var actionButtons: some View {
        VStack(spacing: 18) {
            // Create New Game Button
            NavigationLink(value: AppRoute.funFactWriting) {
                ZStack {
                    // Gradient background
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
                    
                    Text("ابدأ لعبة جديدة")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.createRoom(playerName: playerName)
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
            NavigationLink(value: AppRoute.funFactJoin) {
                ZStack {
                    // Gradient background
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
                    
                    Text("دخول لعبة")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.startBrowsing()
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
    
    // MARK: - Start Animations
    private func startAnimations() {
        // Logo entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoRotation = 0
        }
        
        // Continuous subtle floating animation
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
        FunFactStartPage()
    }
}

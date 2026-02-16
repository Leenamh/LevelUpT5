//
//  TrendingTopicJoinView.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  TrendingTopicJoinView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicJoinView: View {
    @StateObject var vm: TrendingTopicJoinVM
    @Environment(\.dismiss) private var dismiss
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = -5
    @State private var buttonScale: CGFloat = 1.0

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
                    .frame(height: 20)
                
                // Logo
                logoView
                
                Spacer()
                    .frame(height: 60)
                
                // Room Number Input
                roomNumberField
                
                Spacer()
                
                // Join Button
                joinButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [Color("DarkBlue").opacity(0.3), Color("DarkBlue").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    
                    Image(systemName: "chevron.forward")
                        .foregroundColor(Color("DarkBlue"))
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        Image("TrendingTopicsPage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color("DarkBlue").opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Room Number Field
    private var roomNumberField: some View {
        TextField("رقم الغرفة", text: $vm.roomCode)
            .font(.system(size: 16, weight: .medium))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .padding()
            .frame(width: 320, height: 55)
            .background(Color.white)
            .cornerRadius(27.5)
            .overlay(
                RoundedRectangle(cornerRadius: 27.5)
                    .stroke(
                        LinearGradient(
                            colors: [Color("DarkBlue"), Color("DarkBlue").opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color("DarkBlue").opacity(0.2), radius: 10, x: 0, y: 5)
            .onChange(of: vm.roomCode) { newValue in
                // Limit to 5 digits
                if newValue.count > 5 {
                    vm.roomCode = String(newValue.prefix(5))
                }
            }
    }
    
    // MARK: - Join Button
    private var joinButton: some View {
        NavigationLink(value: AppRoute.trendingLobby(
            room: TTRoom(
                code: vm.roomCode.isEmpty ? "55555" : vm.roomCode,
                players: [
                    TTPlayer(name: "حصة"),
                    TTPlayer(name: vm.displayName.isEmpty ? "لاعب" : vm.displayName),
                    TTPlayer(name: "لينا")
                ]
            ),
            isHost: false
        )) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        vm.canJoin ? Color("DarkBlue") : Color("DarkBlue").opacity(0.4),
                        vm.canJoin ? Color("DarkBlue").opacity(0.8) : Color("DarkBlue").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 320, height: 58)
                .cornerRadius(29)
                .shadow(
                    color: (vm.canJoin ? Color("DarkBlue") : Color.gray).opacity(0.5),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                Text("دخول ة")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
            }
        })
        .scaleEffect(buttonScale)
        .disabled(!vm.canJoin)
        .padding(.bottom, 60)
    }
    
    // MARK: - Start Animations
    private func startAnimations() {
        // Logo entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoRotation = 0
        }
        
        // Continuous floating animation
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
        TrendingTopicJoinView(
            vm: TrendingTopicJoinVM(displayName: "حنين")
        )
    }
}

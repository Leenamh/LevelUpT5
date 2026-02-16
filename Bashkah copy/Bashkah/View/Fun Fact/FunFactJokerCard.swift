//
//  FunFactJokerCard.swift
//  Bashkah - Fun Fact Game
//
//  صفحة الجوكر - تظهر للاعب المحظوظ فقط
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactJokerCard: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var navigateToOpinion = false
    @State private var cardScale: CGFloat = 0.8
    @State private var jokerRotation: Double = -10
    @State private var buttonScale: CGFloat = 1.0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("Background"), Color("Background").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Room Number
                roomNumberView
                
                Spacer()
                
                // Joker Card
                jokerCardView
                
                Spacer()
                
                // Next Button
                nextButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToOpinion) {
            FunFactOpinion(viewModel: viewModel)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                ZStack {
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
    
    // MARK: - Room Number View
    private var roomNumberView: some View {
        VStack(spacing: 8) {
            Text("رقم الغرفة")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 10) {
                Text(viewModel.gameRoom?.roomNumber ?? "-----")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Button(action: {
                    UIPasteboard.general.string = viewModel.gameRoom?.roomNumber
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color("Orange"))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
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
        }
        .padding(.top, -20)
    }
    
    // MARK: - Joker Card View
    private var jokerCardView: some View {
        ZStack {
            // Card Background Image
            Image("FactBack1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 360)
                .shadow(color: Color("Orange").opacity(0.4), radius: 20, x: 0, y: 15)
            
            // Joker Icon Overlay
            VStack(spacing: 15) {
                Spacer()
                    .frame(height: 60)
                
                // Top text
                Text("لحد يدري...")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Joker Icon
                Image("joker")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 199, height: 199)
                    .scaleEffect(cardScale)
                    .rotationEffect(.degrees(jokerRotation))
                
                Spacer()
                
                // Bottom text
                VStack(spacing: 12) {
                    Text("انت الجوكر")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("لك فرصة لاختيار اجابتين\nاذا احترت")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                    .frame(height: 60)
            }
            .frame(width: 360, height: 500)
        }
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
                viewModel.proceedToVoting()
                navigateToOpinion = true
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
                .frame(width: 200, height: 56)
                .cornerRadius(28)
                .shadow(color: Color("Orange").opacity(0.5), radius: 15, x: 0, y: 8)
                
                Text("التالي")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(buttonScale)
        .padding(.bottom, 60)
    }
    
    // MARK: - Start Animations
    private func startAnimations() {
        // Card entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            cardScale = 1.0
            jokerRotation = 0
        }
        
        // Continuous celebration animation
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            cardScale = 1.05
        }
        
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            jokerRotation = 3
        }
    }
}

#Preview {
    NavigationStack {
        FunFactJokerCard(viewModel: {
            let vm = FunFactViewModel()
            vm.createRoom(playerName: "حنين")
            return vm
        }())
    }
}

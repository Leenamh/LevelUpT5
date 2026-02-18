//
//  TrendingTopicGameView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicGameView: View {
    @StateObject var vm: TrendingTopicGameVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCard = false
    @State private var cardRotation: Double = 0
    @State private var isFlipped = false
    @State private var buttonScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background gradient
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
                // Top bar
                HStack {
                    Spacer()
                    
                    // Exit Button
                    Button {
                        hapticFeedback()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("DarkBlue").opacity(0.2), Color("DarkBlue").opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(Color("DarkBlue"))
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)

                Spacer()
                
                // Card
                ZStack {
                    // Card Back
                    Image("TrendingTopicsBack1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 283, height: 468)
                        .rotation3DEffect(
                            .degrees(cardRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isFlipped ? 0 : 1)
                    
                    // Card Front with Topic
                    ZStack {
                        Image("TrendingTopicsBack1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 283, height: 468)
                        
                        Text(vm.topic)
                            .font(.system(size: 26, weight: .black))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 70)
                    }
                    .rotation3DEffect(
                        .degrees(cardRotation - 180),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .opacity(isFlipped ? 1 : 0)
                }
                .scaleEffect(showCard ? 1.0 : 0.8)
                .opacity(showCard ? 1.0 : 0.0)

                Spacer()

                // Next Button
                Button {
                    hapticFeedback()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 1.0
                        }
                        
                        // Flip card back
                        withAnimation(.easeInOut(duration: 0.4)) {
                            cardRotation += 180
                            isFlipped.toggle()
                        }
                        
                        // Wait then load next topic
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            vm.nextTopic()
                            
                            // Flip to show new topic
                            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                                cardRotation += 180
                                isFlipped.toggle()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("التالي")
                            .font(.system(size: 18, weight: .bold))
                        
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(.white)
                    .frame(width: 280, height: 58)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 29)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("DarkBlue"),
                                            Color("DarkBlue").opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 29)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .center
                                    )
                                )
                        }
                    )
                    .shadow(color: Color("DarkBlue").opacity(0.4), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 29)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .scaleEffect(buttonScale)
                .opacity(showCard ? 1.0 : 0.0)
                
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 22)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Show card with flip animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                showCard = true
            }
            
            // Flip to show topic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    cardRotation = 180
                    isFlipped = true
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    NavigationStack {
        TrendingTopicGameView(
            vm: TrendingTopicGameVM()
        )
    }
}

//
//  FunFactWritingView.swift
//  Bashkah - Fun Fact Game
//
//  صفحة كتابة الحقائق (5 بطاقات)
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactWritingView: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var showJoker = false
    @State private var showOpinion = false
    @State private var cardScale: CGFloat = 0.9
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
                    .frame(height: 30)
                
                // Fun Fact Card
                funFactCard
                
                Spacer()
                
                // Next/Submit Button
                nextButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showJoker) {
            FunFactJokerCard(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showOpinion) {
            FunFactOpinion(viewModel: viewModel)
        }
        .onAppear {
            // Load saved facts if any
            if let player = viewModel.currentPlayer {
                viewModel.currentPlayerFacts = player.facts
            }
            
            // Card entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                viewModel.leaveRoom()
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
        .padding(.top, -20) // رفعناه فوق
    }
    
    // MARK: - Fun Fact Card
    private var funFactCard: some View {
        ZStack {
            // Card Background Image
            Image("FactBack")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 360)
                .shadow(color: Color("Orange").opacity(0.3), radius: 15, x: 0, y: 10)
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Hint Icon - only show when text is written
                if !viewModel.currentPlayerFacts[viewModel.currentFactIndex].isEmpty {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color("Orange"))
                        .padding(.bottom, 20)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Text Input with orange cursor
                VStack {
                    Spacer()
                    
                    TextField("اكتب الحقيقة", text: $viewModel.currentPlayerFacts[viewModel.currentFactIndex], axis: .vertical)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .lineLimit(8...12)
                        .tint(Color("Orange")) // 👈 Orange cursor
                        .padding(.horizontal, 50)
                    
                    Spacer()
                }
                .frame(height: 280)
                
                Spacer()
                    .frame(height: 20)
                
                // Card Counter with animation
                Text("\(viewModel.currentFactIndex + 1)/5")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("Orange"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color("Orange").opacity(0.15))
                    )
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .scaleEffect(cardScale)
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        let hasText = !viewModel.currentPlayerFacts[viewModel.currentFactIndex].trimmingCharacters(in: .whitespaces).isEmpty
        
        return Button(action: {
            guard hasText else { return }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
                nextCard()
            }
        }) {
            ZStack {
                LinearGradient(
                    colors: hasText ? [
                        Color("Orange"),
                        Color("Orange").opacity(0.8)
                    ] : [
                        Color("Orange").opacity(0.4),
                        Color("Orange").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 56)
                .cornerRadius(28)
                .shadow(
                    color: hasText ? Color("Orange").opacity(0.5) : Color("Orange").opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                HStack(spacing: 8) {
                    Text(viewModel.currentFactIndex == 4 ? "إرسال" : "التالي")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if viewModel.currentFactIndex < 4 {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .scaleEffect(buttonScale)
        .disabled(!hasText)
        .padding(.bottom, 60)
    }
    
    // MARK: - Next Card Logic
    private func nextCard() {
        if viewModel.currentFactIndex < 4 {
            // Animate card out then in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 0.9
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.currentFactIndex += 1
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    cardScale = 1.0
                }
            }
        } else {
            // Submit facts
            viewModel.submitFacts()
            
            // Navigate based on joker status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.isJoker {
                    showJoker = true
                } else {
                    showOpinion = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FunFactWritingView(viewModel: {
            let vm = FunFactViewModel()
            vm.createRoom(playerName: "حنين")
            return vm
        }())
    }
}

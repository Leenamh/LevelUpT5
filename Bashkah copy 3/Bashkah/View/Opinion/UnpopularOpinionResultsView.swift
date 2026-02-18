//
//  Unpopularopinionresultsview .swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  UnpopularOpinionResultsView.swift
//  Bashkah
//
//  Created on 24/08/1447 AH.
//

import SwiftUI

struct UnpopularOpinionResultsView: View {
    @StateObject var vm: UnpopularOpinionResultsVM
    @Environment(\.dismiss) private var dismiss
    @State private var showCard = false
    @State private var showBars = false
    @State private var buttonScale: CGFloat = 1.0

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
                // Top bar
                topBar
                
                Spacer()
                    .frame(height: 20)
                
                // Opinion card
                cardView
                
                Spacer()
                    .frame(height: 30)

                // Results bars
                resultsView
                
                Spacer()

                // Next button
                nextButton
            }
            .padding(.horizontal, 22)
            
            // Tomato animation overlay
            if vm.showTomatoes {
                tomatoAnimation
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "56805D").opacity(0.25), Color(hex: "56805D").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(hex: "56805D"))
                        .font(.system(size: 20, weight: .bold))
                }
            }
            
            Spacer()
        }
        .padding(.top, 50)
    }
    
    // MARK: - Card View
    private var cardView: some View {
        ZStack {
            // Opinion card (smaller)
            Image("unpopularOpinionBackEmpty1")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 400)
                .shadow(color: Color(hex: "56805D").opacity(0.3), radius: 15, x: 0, y: 8)
            
            VStack(spacing: 0) {
                // Player name - at the top inside card
                Text(vm.currentPlayerName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.top, 30)
                
                Spacer()
                
                // Opinion text in the middle
                Text(vm.currentOpinion)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(width: 240, height: 400)
        }
        .scaleEffect(showCard ? 1.0 : 0.8)
        .opacity(showCard ? 1.0 : 0.0)
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        HStack(spacing: 20) {
            // Disagree bar
            VStack(spacing: 8) {
                Text("%\(vm.disagreePercentage)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.red)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
                    .frame(
                        width: 80,
                        height: showBars ? min(CGFloat(vm.disagreePercentage) * 1.5, 150) : 0
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: showBars)
                
                Text("ضد")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            // Agree bar
            VStack(spacing: 8) {
                Text("%\(vm.agreePercentage)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "56805D"))
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "56805D"))
                    .frame(
                        width: 80,
                        height: showBars ? min(CGFloat(vm.agreePercentage) * 1.5, 150) : 0
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: showBars)
                
                Text("مع")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .opacity(showBars ? 1.0 : 0.0)
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        NavigationLink(value: AppRoute.unpopularVoting(room: vm.room, currentPlayerID: UUID())) {
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
                
                Text("التالي")
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
        .padding(.bottom, 60)
    }
    
    // MARK: - Tomato Animation
    private var tomatoAnimation: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Text("🍅")
                    .font(.system(size: CGFloat.random(in: 40...60)))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: vm.showTomatoes ? 800 : -200
                    )
                    .rotation3DEffect(
                        .degrees(vm.showTomatoes ? Double.random(in: 360...720) : 0),
                        axis: (x: 1, y: 1, z: 0)
                    )
                    .opacity(vm.showTomatoes ? 0 : 1)
                    .animation(
                        Animation.easeIn(duration: Double.random(in: 1.0...1.8))
                            .delay(Double(index) * 0.05),
                        value: vm.showTomatoes
                    )
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
            showCard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showBars = true
            
            // Show tomatoes if disagree percentage is high (60% or more)
            if vm.disagreePercentage >= 60 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vm.showTomatoes = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UnpopularOpinionResultsView(
            vm: UnpopularOpinionResultsVM(
                room: UORoom(
                    code: "12345",
                    players: [
                        UOPlayer(name: "حنين", opinion: "ايرون مان افوى واحد")
                    ],
                    currentOpinionIndex: 0
                )
            )
        )
    }
}

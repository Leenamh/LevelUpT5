//
//  Unpopularopinionvotingview.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  UnpopularOpinionVotingView.swift
//  Bashkah
//
//  Created on 24/08/1447 AH.
//

import SwiftUI

struct UnpopularOpinionVotingView: View {
    @StateObject var vm: UnpopularOpinionVotingVM
    @Environment(\.dismiss) private var dismiss
    @State private var showCard = false
    @State private var agreeButtonScale: CGFloat = 1.0
    @State private var disagreeButtonScale: CGFloat = 1.0
    @State private var navigateToResults = false

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

                // Voting buttons
                if !vm.hasVoted {
                    votingButtons
                } else {
                    waitingView
                }
            }
            .padding(.horizontal, 22)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToResults) {
            UnpopularOpinionResultsView(vm: UnpopularOpinionResultsVM(room: vm.room))
        }
        .onChange(of: vm.hasVoted) { voted in
            if voted {
                // Navigate to results after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    navigateToResults = true
                }
            }
        }
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
            // Opinion card background
            Image("unpopularOpinionBackEmpty1")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 500)
                .shadow(color: Color(hex: "56805D").opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                // Player name - at the top inside card
                Text(vm.currentPlayerName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.top, 40)
                
                Spacer()
                
                // Opinion text in the middle
                Text(vm.currentOpinion)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                
                Spacer()
            }
            .frame(width: 300, height: 500)
        }
        .scaleEffect(showCard ? 1.0 : 0.8)
        .opacity(showCard ? 1.0 : 0.0)
    }
    
    // MARK: - Voting Buttons
    private var votingButtons: some View {
        HStack(spacing: 20) {
            // Disagree Button - with tomatoes
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    disagreeButtonScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        disagreeButtonScale = 1.0
                    }
                    vm.vote(agree: false)
                }
            } label: {
                HStack(spacing: 12) {
                    // Tomato emoji
                    HStack(spacing: -8) {
                        Text("🍅")
                            .font(.system(size: 28))
                        
                    }
                    
                    Text("ضد")
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundColor(Color.red)
                .frame(width: 160, height: 60)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .scaleEffect(disagreeButtonScale)
            
            // Agree Button - green solid
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    agreeButtonScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        agreeButtonScale = 1.0
                    }
                    vm.vote(agree: true)
                }
            } label: {
                Text("مع 👌🏻")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(hex: "56805D"))
                    )
                    .shadow(color: Color(hex: "56805D").opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .scaleEffect(agreeButtonScale)
        }
        .padding(.bottom, 60)
    }
    
    // MARK: - Waiting View
    private var waitingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "56805D"))
            
            Text("بانتظار باقي اللاعبين...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(.bottom, 60)
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
            showCard = true
        }
    }
}

#Preview {
    NavigationStack {
        UnpopularOpinionVotingView(
            vm: UnpopularOpinionVotingVM(
                room: UORoom(
                    code: "12345",
                    players: [
                        UOPlayer(name: "", opinion: "القهوة افضل من الشاهي"),
                        UOPlayer(name: "نجد", opinion: "ايرون مان اقوى واحد")
                    ]
                ),
                currentPlayerID: UUID()
            )
        )
    }
}

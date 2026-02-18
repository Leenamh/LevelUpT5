//
//  UnpopularOpinionWritingView.swift
//  Bashkah
//
//  Created by Hneen on 24/08/1447 AH.
//
//
//  UnpopularOpinionWritingView.swift
//  Bashkah
//
//  Created on 24/08/1447 AH.
//

import SwiftUI

struct UnpopularOpinionWritingView: View {
    @StateObject var vm: UnpopularOpinionWritingVM
    @Environment(\.dismiss) private var dismiss
    
    @State private var opinions: [String] = ["", "", "", ""]
    @State private var currentOpinionIndex: Int = 0
    @State private var showCard = false
    @State private var cardScale: CGFloat = 0.9
    @State private var buttonScale: CGFloat = 1.0
    @FocusState private var isTextFieldFocused: Bool

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
                
                // Title
                Text("اكتب آراءك الغير شائعة")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                    .frame(height: 30)
                
                // Card with text input
                cardView
                
                Spacer()

                // Submit Button
                nextButton
            }
            .padding(.horizontal, 22)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: AppRoute.self) { route in
            routeDestination(for: route)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                showCard = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                cardScale = 1.0
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
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
            // Background card image
            Image("unpopularOpinionBackEmpty1")
                .resizable()
                .scaledToFit()
                .frame(width: 283, height: 468)
                .shadow(color: Color(hex: "56805D").opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Hint Icon
                if !opinions[currentOpinionIndex].isEmpty {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "56805D"))
                        .padding(.bottom, 20)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Text Input
                VStack {
                    Spacer()
                    
                    TextField("اكتب رأيك هنا", text: $opinions[currentOpinionIndex], axis: .vertical)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .lineLimit(8...12)
                        .tint(Color(hex: "56805D"))
                        .padding(.horizontal, 50)
                        .focused($isTextFieldFocused)
                    
                    Spacer()
                }
                .frame(height: 280)
                
                Spacer()
                    .frame(height: 20)
                
                // Opinion Counter
                Text("\(currentOpinionIndex + 1)/4")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "56805D"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "56805D").opacity(0.15))
                    )
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .scaleEffect(cardScale)
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        let hasText = !opinions[currentOpinionIndex].trimmingCharacters(in: .whitespaces).isEmpty
        
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
                        Color(hex: "56805D"),
                        Color(hex: "56805D").opacity(0.8)
                    ] : [
                        Color(hex: "56805D").opacity(0.4),
                        Color(hex: "56805D").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 56)
                .cornerRadius(28)
                .shadow(
                    color: hasText ? Color(hex: "56805D").opacity(0.5) : Color(hex: "56805D").opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                HStack(spacing: 8) {
                    Text(currentOpinionIndex == 3 ? "إرسال" : "التالي")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if currentOpinionIndex < 3 {
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
        isTextFieldFocused = false
        
        if currentOpinionIndex < 3 {
            // Animate card out then in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 0.9
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentOpinionIndex += 1
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    cardScale = 1.0
                }
            }
        } else {
            // Submit all opinions and navigate to lobby
            vm.saveOpinion(opinions.joined(separator: "|||"))
            
            // Create room with player
            let player = UOPlayer(name: vm.playerName, opinion: opinions.joined(separator: "|||"))
            let room = UORoom(code: vm.roomCode, players: [player])
            
            // Navigate to lobby
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Use NavigationLink value navigation
            }
        }
    }
    
    // MARK: - Route Destination
    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .unpopularLobby(let room, let isHost):
            UnpopularOpinionLobbyView(vm: UnpopularOpinionLobbyVM(room: room, isHost: isHost))
        default:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        UnpopularOpinionWritingView(
            vm: UnpopularOpinionWritingVM(roomCode: "12345", playerName: "حنين", isHost: true)
        )
    }
}

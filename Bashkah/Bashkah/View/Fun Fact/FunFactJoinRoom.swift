//
//  FunFactJoinRoom.swift
//  Bashkah - Fun Fact Game
//
//  صفحة الانضمام للغرفة
//  Created by Hneen on 23/08/1447 AH.
//

import SwiftUI

struct FunFactJoinRoom: View {
    @ObservedObject var viewModel: FunFactViewModel
    @State private var roomNumber: String = ""
    @State private var showInvalidAlert = false
    @State private var navigateToWriting = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = -5
    @State private var buttonScale: CGFloat = 1.0
    @Environment(\.dismiss) var dismiss
    
    // Computed property for button enabled state
    private var isRoomNumberValid: Bool {
        !roomNumber.isEmpty
    }
    
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
        .navigationDestination(isPresented: $navigateToWriting) {
            FunFactWritingView(viewModel: viewModel)
        }
        .alert("خطأ", isPresented: $showInvalidAlert) {
            Button("حسناً", role: .cancel) { }
        } message: {
            Text("رقم الغرفة يجب أن يكون 5 أرقام")
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            viewModel.stopBrowsing()
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
    
    // MARK: - Logo View
    private var logoView: some View {
        Image("funFact 1")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color("Orange").opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Room Number Field
    private var roomNumberField: some View {
        TextField("رقم الغرفة", text: $roomNumber)
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
                            colors: [Color("Orange"), Color("Orange").opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color("Orange").opacity(0.2), radius: 10, x: 0, y: 5)
            .onChange(of: roomNumber) { newValue in
                // Limit to 5 digits
                if newValue.count > 5 {
                    roomNumber = String(newValue.prefix(5))
                }
            }
    }
    
    // MARK: - Join Button
    private var joinButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
                joinRoom()
            }
        }) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        isRoomNumberValid ? Color("Orange") : Color("Orange").opacity(0.4),
                        isRoomNumberValid ? Color("Orange").opacity(0.8) : Color("Orange").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 320, height: 58)
                .cornerRadius(29)
                .shadow(
                    color: (isRoomNumberValid ? Color("Orange") : Color.gray).opacity(0.5),
                    radius: 15,
                    x: 0,
                    y: 8
                )
                
                Text("دخول اللعبة")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(buttonScale)
        .disabled(!isRoomNumberValid)
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
    
    // MARK: - Join Room
    private func joinRoom() {
        let trimmed = roomNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // No validation - accept any input
        guard !trimmed.isEmpty else { return }
        
        guard let player = viewModel.currentPlayer else { return }
        
        viewModel.joinRoom(roomNumber: trimmed, playerName: player.name)
        
        // Wait for connection then navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if viewModel.gameRoom != nil {
                navigateToWriting = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        FunFactJoinRoom(viewModel: {
            let vm = FunFactViewModel()
            vm.currentPlayer = FunFactPlayer(name: "حنين", deviceID: "test")
            return vm
        }())
    }
}

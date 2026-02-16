//
//  IntroView.swift
//  Bashkah
//
//  Created by leena almusharraf on 13/02/2026.
//


import SwiftUI

struct IntroView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = IntroViewModel()
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = -5
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [Color("Background"), Color("Background").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Back Button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            LinearGradient(
                                colors: [Color("Orange").opacity(0.3),
                                         Color("Orange").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 40, height: 40)
                            .cornerRadius(20)
                            
                            Image(systemName: "chevron.forward")
                                .foregroundColor(Color("Orange"))
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer().frame(height: 20)
                
                // Logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 269, height: 269)
                    .scaleEffect(logoScale)
                    .rotationEffect(.degrees(logoRotation))
                    .shadow(color: Color("Orange").opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10)
                
                Spacer().frame(height: 60)
                
                VStack(spacing: 15) {
                    
                    Text("ادخل اسمك")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("Orange"))
                    
                    TextField("اسمك", text: $vm.nameInput)
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 320, height: 55)
                        .background(Color.white)
                        .cornerRadius(27.5)
                    
                    Button(action: {
                        vm.createPlayer()
                    }) {
                        ZStack {
                            LinearGradient(
                                colors: [
                                    canContinue ? Color("Orange")
                                    : Color("Orange").opacity(0.4),
                                    
                                    canContinue ? Color("Orange").opacity(0.8)
                                    : Color("Orange").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 320, height: 58)
                            .cornerRadius(29)
                            
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("ابدأ")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(!canContinue || vm.isLoading)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $vm.goToStartPage) {
            StartPageView()
        }
        .alert("Error",
               isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { _ in vm.errorMessage = nil }
               )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var canContinue: Bool {
        !vm.nameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8,
                              dampingFraction: 0.6)) {
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

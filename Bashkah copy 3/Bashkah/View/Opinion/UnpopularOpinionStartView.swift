import SwiftUI

struct UnpopularOpinionStartView: View {
    
    @AppStorage("playerName") private var playerName: String = ""
    @Environment(\.dismiss) private var dismiss   // ✅ Proper back
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = -5
    @State private var buttonScale1: CGFloat = 1.0
    @State private var buttonScale2: CGFloat = 1.0

    var body: some View {
        ZStack {
            
            // MARK: Background
            LinearGradient(
                colors: [
                    Color("Background"),
                    Color("Background").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: Back Button
                backButton
                
                Spacer()
                
                // MARK: Logo
                logoView
                
                Spacer()
                    .frame(height: 150)
                
                // MARK: Buttons
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
            startAnimations()
        }
    }
    
    
    // MARK: - Back Button (FIXED)
    
    private var backButton: some View {
        HStack {
            Spacer()
            
            Button {
                dismiss()   // ✅ Pop back to StartPageView
            } label: {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "56805D").opacity(0.3),
                            Color(hex: "56805D").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    
                    Image(systemName: "chevron.forward")
                        .foregroundColor(Color(hex: "56805D"))
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    
    // MARK: - Logo
    
    private var logoView: some View {
        Image("unpopularOpinionPage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color(hex: "56805D").opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10)
    }
    
    
    // MARK: - Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 18) {
            
            // Create Game
            NavigationLink(value: AppRoute.unpopularWriting(
                roomCode: String(format: "%05d", Int.random(in: 10000...99999)),
                isHost: true
            )) {
                gradientButton(title: "ابدأ لعبة جديدة")
            }
            .simultaneousGesture(TapGesture().onEnded {
                animateButton($buttonScale1)
            })
            .scaleEffect(buttonScale1)
            
            
            // Join Game
            NavigationLink(value: AppRoute.unpopularJoin) {
                gradientButton(title: "دخول لعبة")
            }
            .simultaneousGesture(TapGesture().onEnded {
                animateButton($buttonScale2)
            })
            .scaleEffect(buttonScale2)
        }
    }
    
    
    // MARK: - Gradient Button
    
    private func gradientButton(title: String) -> some View {
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
            .shadow(
                color: Color(hex: "56805D").opacity(0.5),
                radius: 15,
                x: 0,
                y: 8
            )
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    
    // MARK: - Button Animation (SAFE)
    
    private func animateButton(_ scale: Binding<CGFloat>) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale.wrappedValue = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale.wrappedValue = 1.0
            }
        }
    }
    
    
    // MARK: - Route Destination
    
    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
            
        case .unpopularJoin:
            UnpopularOpinionJoinView(
                vm: UnpopularOpinionJoinVM(displayName: playerName)
            )
            
        case .unpopularWriting(let roomCode, let isHost):
            UnpopularOpinionWritingView(
                vm: UnpopularOpinionWritingVM(
                    roomCode: roomCode,
                    playerName: playerName,
                    isHost: isHost
                )
            )
            
        case .unpopularLobby(let room, let isHost):
            UnpopularOpinionLobbyView(
                vm: UnpopularOpinionLobbyVM(room: room, isHost: isHost)
            )
            
        case .unpopularVoting(let room, let playerID):
            UnpopularOpinionVotingView(
                vm: UnpopularOpinionVotingVM(room: room, currentPlayerID: playerID)
            )
            
        case .unpopularResults(let room):
            UnpopularOpinionResultsView(
                vm: UnpopularOpinionResultsVM(room: room)
            )
            
        default:
            EmptyView()
        }
    }
    
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
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


#Preview {
    NavigationStack {
        UnpopularOpinionStartView()
    }
}

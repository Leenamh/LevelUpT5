import SwiftUI

struct TrendingTopicStartView: View {
    
    @AppStorage("playerName") private var playerName: String = ""
    @Environment(\.dismiss) private var dismiss   // ✅ Back
    
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
                    .frame(height: 80)
                
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
                dismiss()   // ✅ Pop back
            } label: {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("DarkBlue").opacity(0.3),
                            Color("DarkBlue").opacity(0.1)
                        ],
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
    
    
    // MARK: - Logo
    
    private var logoView: some View {
        Image("TrendingTopicsPage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 269, height: 269)
            .scaleEffect(logoScale)
            .rotationEffect(.degrees(logoRotation))
            .shadow(color: Color("DarkBlue").opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10)
    }
    
    
    // MARK: - Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 18) {
            
            // Create Game
            NavigationLink(value: AppRoute.trendingLobby(
                room: TTRoom(
                    code: String(format: "%05d", Int.random(in: 10000...99999)),
                    players: [TTPlayer(name: playerName)]
                ),
                isHost: true
            )) {
                gradientButton(title: "ابدأ لعبة جديدة")
            }
            .simultaneousGesture(TapGesture().onEnded {
                animateButton($buttonScale1)
            })
            .scaleEffect(buttonScale1)
            
            
            // Join Game
            NavigationLink(value: AppRoute.trendingJoin) {
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
                    Color("DarkBlue"),
                    Color("DarkBlue").opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 320, height: 58)
            .cornerRadius(29)
            .shadow(
                color: Color("DarkBlue").opacity(0.5),
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
            
        case .trendingJoin:
            TrendingTopicJoinView(
                vm: TrendingTopicJoinVM(displayName: playerName)
            )
            
        case .trendingLobby(let room, let isHost):
            TrendingTopicLobbyView(
                vm: TrendingTopicLobbyVM(room: room, isHost: isHost)
            )
            
        case .trendingGame:
            TrendingTopicGameView(
                vm: TrendingTopicGameVM()
            )
            
        default:
            EmptyView()
        }
    }
    
    
    // MARK: - Logo Animations
    
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
        TrendingTopicStartView()
    }
}

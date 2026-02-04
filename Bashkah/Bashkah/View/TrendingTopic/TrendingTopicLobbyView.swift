//
//  TrendingTopicLobbyView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicLobbyView: View {
    @Binding var path: NavigationPath
    @StateObject var vm: TrendingTopicLobbyVM
    @State private var showCopiedToast = false


    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 14) {

                Text("بانتظار اللاعبين")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.black.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)


                VStack(spacing: 8) {
                    Text("رقم الغرفة")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.65))
                    
                    HStack(spacing: 10) {
                        Text(vm.room.code)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        
                        
                        Button {
                            vm.copyCode()
                            
                            // Haptic feedback
                            let gen = UINotificationFeedbackGenerator()
                            gen.notificationOccurred(.success)
                            
                            // Show "copied" UI
                            withAnimation(.easeInOut) { showCopiedToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation(.easeInOut) { showCopiedToast = false }
                            }
                        } label: {
                            Image(systemName: showCopiedToast ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundStyle(showCopiedToast ? .green : .black.opacity(0.7))
                        }
                    }
                    
                    
                    if showCopiedToast {
                        Text("تم نسخ رقم الغرفة ")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }


                Spacer().frame(height: 30)

                let cols = vm.columns
                HStack(alignment: .top, spacing: 80) {
                    VStack(spacing: 16) {
                        ForEach(cols.0) { p in
                            Text(p.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.black.opacity(0.85))
                        }
                    }

                    VStack(spacing: 16) {
                        ForEach(cols.1) { p in
                            Text(p.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.black.opacity(0.85))
                        }
                    }
                }

                Spacer()

                Button {
                    path.append(AppRoute.trendingGame)
                } label: {
                    Text("ابدأ")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("Background"))
                        .frame(width: 140, height: 46)
                        .background(vm.isHost ? Color("DarkBlue") : Color("DisabledButton"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!vm.isHost)

                Spacer().frame(height: 10)
            }
            .padding(.horizontal, 22)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if !path.isEmpty { path.removeLast() } // back to Join/Start
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.black)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

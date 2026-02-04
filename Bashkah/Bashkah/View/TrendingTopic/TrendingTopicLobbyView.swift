//
//  TrendingTopicLobbyView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicLobbyView: View {
    @StateObject var vm: TrendingTopicLobbyVM

    var body: some View {
        ZStack {
            Color("TrendingTopicsBack").ignoresSafeArea()

            VStack(spacing: 14) {

                HStack {
                    Text("بانتظار اللاعبين")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.black.opacity(0.85))
                    Spacer()
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("رقم الغرفة")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.65))

                    HStack(spacing: 10) {
                        Text(vm.room.code)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)

                        Button(action: vm.copyCode) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.black.opacity(0.7))
                        }
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

                NavigationLink {
                    TrendingTopicGameView(vm: TrendingTopicGameVM())
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.black)
                        .padding(.leading,20)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
    }
        
}


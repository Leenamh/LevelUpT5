//
//  TrendingTopicJoinView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicJoinView: View {
    @StateObject var vm: TrendingTopicJoinVM

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image("TrendingTopicsPage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)

                TextField("ادخل رقم الغرفة", text: $vm.roomCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 260)
                    .background(Color.white.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("DarkBlue"), lineWidth: 1.5)
                    )

                NavigationLink {
                    let room = TTRoom(
                        code: vm.roomCode.isEmpty ? "55555" : vm.roomCode,
                        players: [
                            TTPlayer(name: "حصة"),
                            TTPlayer(name: vm.displayName.isEmpty ? "لاعب" : vm.displayName),
                            TTPlayer(name: "لينا")
                        ]
                    )
                    TrendingTopicLobbyView(vm: TrendingTopicLobbyVM(room: room, isHost: false))
                } label: {
                    Text("الانضمام")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("ButtonText"))
                        .frame(width: 180, height: 48)
                        .background(vm.canJoin ? Color("GameButton") : Color("DisabledButton"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!vm.canJoin)

                Spacer()
            }
            .padding(.horizontal, 22)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarTitleDisplayMode(.inline)
    }
}


//
//  TrendingTopicStartView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI


struct TrendingTopicStartView: View {
    @Binding var path: NavigationPath
    @StateObject var vm = TrendingTopicStartVM()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 18) {

                Image("TrendingTopicsPage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 270, height: 250)
                    .padding(.vertical, 60)

                TextField(
                    "",
                    text: $vm.name,
                    prompt: Text("ادخل اسمك")
                        .foregroundColor(.gray)
                )
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(width: 240, height: 48)
                .background(Color.white.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DarkBlue"), lineWidth: 2)
                )


                Button {
                    let room = TTRoom(
                        code: "55555",
                        players: [
                            TTPlayer(name: "حصة"),
                            TTPlayer(name: "حنين"),
                            TTPlayer(name: "لينا"),
                            TTPlayer(name: "روان"),
                            TTPlayer(name: "ميسم"),
                            TTPlayer(name: "نجد")
                        ]
                    )
                    path.append(AppRoute.trendingLobby(room: room, isHost: true))
                } label: {
                    Text("ابدأ لعبة جديدة")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("Background"))
                        .frame(width: 240, height: 48)
                        .background(vm.canStart ? Color("DarkBlue") : Color("DisabledButton"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!vm.canStart)
                .padding(.top, 70)

                Button {
                    path.append(AppRoute.trendingJoin(name: vm.name))
                } label: {
                    Text("الانضمام")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("Background"))
                        .frame(width: 240, height: 48)
                        .background(vm.canStart ? Color("DarkBlue") : Color("DisabledButton"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // go back to HomePage
                    path.removeLast(path.count)
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.black)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

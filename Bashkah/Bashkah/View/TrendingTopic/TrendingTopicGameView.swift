//
//  TrendingTopicGameView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI


struct TrendingTopicGameView: View {
    @StateObject var vm: TrendingTopicGameVM
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 18) {

                // Top bar
                HStack {
                    // Coins on left (as in your screenshot)
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(.yellow)
                        Text("\(vm.coins)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    // Door on right
                    Button {
                        path.removeLast(path.count) // back to root (Home)
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.black)
                    }
                }
                .padding(.top, 12)

                // Card
                ZStack {
                    Image("TrendingTopicsBack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 283, height: 468)

                    Text(vm.topic)
                        .font(.system(size: 26, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                }

                // Button
                Button {
                    vm.nextTopic()
                } label: {
                    Text("التالي")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("Background"))
                        .frame(width: 240, height: 48)
                        .background(Color("DarkBlue"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 6)

            }
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity, alignment: .top) // ✅ anchor to top
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
    }
}

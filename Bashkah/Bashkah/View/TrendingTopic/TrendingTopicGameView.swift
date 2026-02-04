//
//  TrendingTopicGameView.swift
//  Bashkah
//
//  Created by Najd Alsabi on 16/08/1447 AH.
//

import SwiftUI

struct TrendingTopicGameView: View {
    @StateObject var vm: TrendingTopicGameVM

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 14) {

                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.black)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(vm.coins)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.yellow)
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer().frame(height: 10)

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
                .padding(.top, 10)


                Button {
                    vm.nextTopic()
                } label: {
                    Text("التالي")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("Background"))
                        .frame(width: 160, height: 48)
                        .background(Color("DarkBlue"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer().frame(height: 10)
            }
            .padding(.horizontal, 22)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
    }
}


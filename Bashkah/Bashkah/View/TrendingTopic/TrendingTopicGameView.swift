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
                    Button {
                        path.removeLast(path.count)
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.black)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(.yellow)
                        Text("\(vm.coins)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.yellow)
                    }

                }
                .padding(.top, 4)
                .padding(.bottom, 10)

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
                        .padding(.horizontal, 70)
                }
                .padding(.top, 50)

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
                .padding(.top, 80)

            }
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden(true)
    }
}

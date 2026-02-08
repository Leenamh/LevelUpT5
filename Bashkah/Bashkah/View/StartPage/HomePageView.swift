//
//  HomePageView.swift
//  Bashkah
//
//  Created by leena almusharraf on 05/02/2026.
//


import SwiftUI

struct HomePageView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Text("الصفحة الرئيسية")
                    .font(.system(size: 28, weight: .bold))

                Button {
                    path.append(AppRoute.trendingStart)
                } label: {
                    Text("Trending Topic")
                        .font(.system(size: 18, weight: .semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("DarkBlue"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

            }
        }
    }
}

#Preview {
    HomePageView(path: .constant(NavigationPath()))
}

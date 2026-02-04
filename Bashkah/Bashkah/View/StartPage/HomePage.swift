//
//  HomePage.swift
//  Bashkah
//
//  Created by Hneen on 15/08/1447 AH.
//

import SwiftUI

struct HomePageView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 20) {
                Text("الصفحة الرئيسية")
                    .font(.system(size: 28, weight: .bold))

                Button("Trending Topic") {
                    path.append(AppRoute.trendingStart)
                }
                .padding()
                .background(Color("DarkBlue"))
                .foregroundStyle(Color("Background"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

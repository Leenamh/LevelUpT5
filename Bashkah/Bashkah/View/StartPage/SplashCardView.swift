import SwiftUI

struct SplashCardView: View {

    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 180, height: 260)
            .cornerRadius(5)
    }
}

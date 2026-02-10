import SwiftUI

enum SwipeDirection {
    case left
    case right
}

struct StartPageCardView: View {
    let frontImage: String
    let backImage: String
    let isFront: Bool
    let onFlipChanged: (Bool) -> Void   // 🔴 NEW
    let onTap: () -> Void
    let onSwipe: (SwipeDirection) -> Void

    @State private var flipped = false
    @State private var rotation: Double = 0
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Image(flipped ? backImage : frontImage)
            .resizable()
            .scaledToFill()
            .frame(width: 235, height: 390)
            .clipped()
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .rotation3DEffect(.degrees(rotation), axis: (0, 1, 0))
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isFront {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        guard isFront else {
                            dragOffset = .zero
                            return
                        }

                        let threshold: CGFloat = 80

                        if value.translation.width < -threshold {
                            onSwipe(.left)
                        } else if value.translation.width > threshold {
                            onSwipe(.right)
                        }

                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
            .onTapGesture {
                onTap()
                if isFront {
                    flip()
                }
            }
            .onChange(of: isFront) { newValue in
                if newValue == false {
                    resetToFront()
                }
            }
    }

    private func flip() {
        withAnimation(.easeIn(duration: 0.25)) {
            rotation += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            flipped.toggle()
            onFlipChanged(flipped)   // 🔴 notify parent
            withAnimation(.easeOut(duration: 0.25)) {
                rotation += 90
            }
        }
    }

    private func resetToFront() {
        flipped = false
        rotation = 0
        onFlipChanged(false)        // 🔴 notify parent
    }
}

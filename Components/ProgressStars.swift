import SwiftUI

struct ProgressStars: View {
    let count: Int
    let total: Int
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Text("⭐")
                    .font(.system(size: size))
                    .opacity(i < count ? 1 : 0.3)
                    .grayscale(i < count ? 0 : 1)
                    .scaleEffect(i < count ? 1 : 0.85)
                    .animation(.easeInOut(duration: 0.3), value: count)
            }
        }
    }
}

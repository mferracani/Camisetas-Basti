import SwiftUI

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            SoundManager.shared.playTap()
            action()
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(Color(hex: "#7A4E1B"))
                .frame(width: 64, height: 64)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

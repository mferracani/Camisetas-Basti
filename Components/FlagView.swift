import SwiftUI

struct FlagView: View {
    let country: Country
    let width: CGFloat
    let height: CGFloat
    let rounded: CGFloat
    
    var body: some View {
        switch country.id {
        case "arg":
            argentinaFlag
        case "eng":
            englandFlag
        case "esp":
            spainFlag
        case "ita":
            italyFlag
        case "fra":
            franceFlag
        case "ger":
            germanyFlag
        default:
            Rectangle().fill(Color.gray)
        }
    }
    
    private var argentinaFlag: some View {
        VStack(spacing: 0) {
            Color(hex: "#75AADB").frame(height: height / 3)
            Color.white.frame(height: height / 3)
                .overlay(sun)
            Color(hex: "#75AADB").frame(height: height / 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
    
    private var sun: some View {
        ZStack {
            Circle().fill(Color(hex: "#FCBF49")).frame(width: height / 6)
            Circle().stroke(Color(hex: "#B07900"), lineWidth: 0.8).frame(width: height / 6)
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color(hex: "#FCBF49"))
                    .frame(width: 1.6, height: height / 18)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }
    
    private var englandFlag: some View {
        ZStack {
            Color.white
            Rectangle().fill(Color(hex: "#CE1124")).frame(width: width * 0.15)
            Rectangle().fill(Color(hex: "#CE1124")).frame(height: height * 0.214)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
    
    private var spainFlag: some View {
        VStack(spacing: 0) {
            Color(hex: "#AA151B").frame(height: height * 0.25)
            Color(hex: "#F1BF00").frame(height: height * 0.5)
            Color(hex: "#AA151B").frame(height: height * 0.25)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
    
    private var italyFlag: some View {
        HStack(spacing: 0) {
            Color(hex: "#008C45").frame(width: width / 3)
            Color(hex: "#F4F5F0").frame(width: width / 3)
            Color(hex: "#CD212A").frame(width: width / 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
    
    private var franceFlag: some View {
        HStack(spacing: 0) {
            Color(hex: "#0055A4").frame(width: width / 3)
            Color.white.frame(width: width / 3)
            Color(hex: "#EF4135").frame(width: width / 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
    
    private var germanyFlag: some View {
        VStack(spacing: 0) {
            Color.black.frame(height: height / 3)
            Color(hex: "#DD0000").frame(height: height / 3)
            Color(hex: "#FFCE00").frame(height: height / 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: rounded))
    }
}

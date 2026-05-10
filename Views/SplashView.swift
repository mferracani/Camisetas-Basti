import SwiftUI

struct SplashView: View {
    @State private var revealPct: Double = 0
    @State private var isComplete = false
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#FEF9E7").ignoresSafeArea()

                HStack(spacing: 72) {
                    ShirtView(
                        team: Team(
                            id: "splash",
                            name: "",
                            short: "",
                            home: Kit(pattern: .stripesV, colors: ["#75AADB", "#FFFFFF"]),
                            away: Kit(pattern: .solid, colors: ["#2C3E50"]),
                            crest: Crest(shape: .round, text: "CB", colors: ["#FFC93C", "#3D2A1F"])
                        ),
                        kit: "home",
                        size: min(geo.size.height * 0.48, 360),
                        mode: .partial,
                        revealPct: revealPct
                    )
                    .shadow(color: Color(hex: "#3D2A1F").opacity(0.14), radius: 24, x: 0, y: 18)

                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CAMISETAS")
                                .font(.custom("Nunito-Black", size: min(geo.size.width * 0.06, 82)))
                                .foregroundColor(Color(hex: "#3D2A1F"))

                            Text("BASTI")
                                .font(.custom("Nunito-Black", size: min(geo.size.width * 0.06, 82)))
                                .foregroundColor(Color(hex: "#FF7B3D"))
                        }
                        .opacity(revealPct > 0.8 ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: revealPct)

                        Text("TOCA PARA JUGAR")
                            .font(.custom("Nunito-Black", size: 22))
                            .foregroundColor(Color(hex: "#7A4E1B").opacity(0.6))
                            .opacity(isComplete ? 1 : 0)
                    }
                }
                .frame(maxWidth: 1100, maxHeight: .infinity)
                .padding(.horizontal, 64)
            }
        }
        .onAppear {
            animateReveal()
        }
        .onTapGesture {
            if isComplete {
                onComplete()
            }
        }
    }

    private func animateReveal() {
        let steps = 60
        let duration = 1.5
        let stepDuration = duration / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                revealPct = Double(i) / Double(steps)
                if i == steps {
                    isComplete = true
                    SoundManager.shared.playCelebrate()
                }
            }
        }
    }
}

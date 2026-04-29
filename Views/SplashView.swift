import SwiftUI

struct SplashView: View {
    @State private var revealPct: Double = 0
    @State private var isComplete = false
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "#FEF9E7").ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
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
                        size: 200,
                        mode: .partial,
                        revealPct: revealPct
                    )
                }
                
                VStack(spacing: 8) {
                    Text("CAMISETAS")
                        .font(.custom("Nunito-Black", size: 42))
                        .foregroundColor(Color(hex: "#3D2A1F"))
                    
                    Text("BASTI")
                        .font(.custom("Nunito-Black", size: 42))
                        .foregroundColor(Color(hex: "#FF7B3D"))
                }
                .opacity(revealPct > 0.8 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: revealPct)
                
                Spacer()
                
                Text("TOCA PARA JUGAR")
                    .font(.custom("Nunito-Black", size: 18))
                    .foregroundColor(Color(hex: "#7A4E1B").opacity(0.6))
                    .opacity(isComplete ? 1 : 0)
                    .padding(.bottom, 40)
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

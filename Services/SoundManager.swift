import AVFoundation

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    private let volume: Float = 0.7
    
    enum Sound: String, CaseIterable {
        case tap = "tap"
        case success = "success"
        case celebrate = "celebrate"
        case errorSoft = "error-soft"
    }
    
    private init() {
        configureSession()
        preloadAll()
    }
    
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session error: \(error)")
        }
    }
    
    private func preloadAll() {
        for sound in Sound.allCases {
            load(sound)
        }
    }
    
    private func load(_ sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[sound.rawValue] = player
        } catch {
            print("⚠️ Sound load error: \(sound.rawValue)")
        }
    }
    
    func play(_ sound: Sound) {
        guard let player = players[sound.rawValue] else { return }
        player.currentTime = 0
        player.play()
    }
    
    func playTap() { play(.tap) }
    func playSuccess() { play(.success) }
    func playCelebrate() { play(.celebrate) }
    func playError() { play(.errorSoft) }
}

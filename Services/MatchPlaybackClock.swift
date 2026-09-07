import Combine
import QuartzCore

/// One monotonic playhead for players, ball, score and commentary. A delayed
/// frame never causes a large catch-up jump, and background time is not played.
struct MatchPlaybackTime {
    private(set) var elapsed = 0.0
    private var lastTimestamp: Double?

    mutating func advance(to timestamp: Double) {
        guard timestamp.isFinite else { return }
        if let lastTimestamp {
            guard timestamp >= lastTimestamp else { return }
            elapsed += min(1.0 / 15.0, timestamp - lastTimestamp)
        }
        lastTimestamp = timestamp
    }

    mutating func seek(to value: Double) {
        elapsed = value.isFinite ? max(0, value) : 0
        suspend()
    }

    mutating func suspend() { lastTimestamp = nil }
}

@MainActor
final class MatchPlaybackClock: ObservableObject {
    @Published private(set) var elapsed = 0.0
    private var time = MatchPlaybackTime()
    private var displayLink: CADisplayLink?

    func seek(to value: Double) {
        time.seek(to: value)
        elapsed = time.elapsed
    }

    func start(reducedMotion: Bool) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--motion-diagnostics") { print("MATCH-CLOCK start") }
        #endif
        if displayLink == nil {
            let target = DisplayTarget()
            target.clock = self
            let link = CADisplayLink(target: target, selector: #selector(DisplayTarget.draw(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        let fps: Float = reducedMotion ? 15 : 60
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: fps, maximum: fps, preferred: fps)
        time.suspend()
        displayLink?.isPaused = false
    }

    func pause() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--motion-diagnostics") { print("MATCH-CLOCK pause \(elapsed)") }
        #endif
        displayLink?.isPaused = true
        time.suspend()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        time.suspend()
    }

    private func draw(_ link: CADisplayLink) {
        #if DEBUG
        if elapsed == 0, ProcessInfo.processInfo.arguments.contains("--motion-diagnostics") { print("MATCH-CLOCK first-frame \(link.targetTimestamp)") }
        #endif
        time.advance(to: link.targetTimestamp)
        elapsed = time.elapsed
    }

    // CADisplayLink retains its target. This proxy must not retain the view's
    // clock; disappearing modals stop explicitly, with this as a final safeguard.
    @MainActor private final class DisplayTarget: NSObject {
        weak var clock: MatchPlaybackClock?

        @objc func draw(_ link: CADisplayLink) {
            guard let clock else { link.invalidate(); return }
            clock.draw(link)
        }
    }
}

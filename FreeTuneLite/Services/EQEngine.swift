import AVFoundation

/// AVAudioEngine chain used ONLY for downloaded (offline) songs:
/// player -> 5-band EQ -> reverb -> main mixer.
/// Streams play through AVPlayer (lighter for a 1 GB-RAM phone).
final class EQEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 5)
    private let reverb = AVAudioUnitReverb()
    private var file: AVAudioFile?
    private var stopped = true
    private var endHandler: (() -> Void)?

    private static let bandFrequencies: [Float] = [60, 230, 910, 3600, 14000]

    init() {
        engine.attach(player)
        engine.attach(eq)
        engine.attach(reverb)
        engine.connect(player, to: eq, format: nil)
        engine.connect(eq, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)
        reverb.wetDryMix = 22
        applySettings()
    }

    func applySettings() {
        let s = SettingsStore.shared
        let gains = s.eqGains
        for i in 0..<5 {
            let band = eq.bands[i]
            band.frequency = EQEngine.bandFrequencies[i]
            band.gain = gains[i]
            band.bypass = !s.eqOn
            if i == 0 {
                band.filterType = .lowShelf
            } else if i == 4 {
                band.filterType = .highShelf
            } else {
                band.filterType = .parametric
                band.bandwidth = 0.85
            }
        }
        reverb.wetDryMix = 22
        reverb.bypass = !s.reverbOn
    }

    var isPlaying: Bool {
        !stopped && player.isPlaying
    }

    func play(url: URL, onEnd: @escaping () -> Void) {
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            let f = try AVAudioFile(forReading: url)
            try engine.start()
            file = f
            endHandler = onEnd
            stopped = false
            player.scheduleFile(f, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    guard let self, !self.stopped else { return }
                    self.hardStop()
                    self.endHandler?()
                }
            }
            player.play()
        } catch {
            stopped = true
            file = nil
            DispatchQueue.main.async {
                onEnd()
            }
        }
    }

    func pause() {
        player.pause()
    }

    func resume() {
        if !stopped {
            player.play()
        }
    }

    func stop() {
        hardStop()
        endHandler = nil
    }

    private func hardStop() {
        stopped = true
        player.stop()
        engine.stop()
        file = nil
    }

    /// Seeking in a scheduled file = stop current schedule, schedule the
    /// remaining segment from the new position, keep playing.
    func seek(to seconds: Double) {
        guard let f = file, !stopped else { return }
        let rate = f.processingFormat.sampleRate
        guard rate > 0 else { return }
        let start = AVAudioFramePosition(max(0, min(seconds * rate, Double(f.length) - 1)))
        let remaining = f.length - start
        guard remaining > 0 else { return }

        stopped = true          // invalidate any old completion handler
        player.stop()           // old completion fires but is guarded
        stopped = false

        player.scheduleSegment(
            f,
            startingFrame: start,
            frameCount: AVAudioFrameCount(remaining),
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                guard let self, !self.stopped else { return }
                self.hardStop()
                self.endHandler?()
            }
        }
        player.play()
    }

    var elapsed: Double {
        guard let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime),
              playerTime.sampleRate > 0 else { return 0 }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    var totalDuration: Double {
        guard let f = file,
              f.processingFormat.sampleRate > 0 else { return 0 }
        return Double(f.length) / f.processingFormat.sampleRate
    }
}

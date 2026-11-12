import AVFoundation
import MediaPlayer

/// Weak observer registry: any screen can listen to player updates without
/// creating retain cycles. Blocks must capture their owner weakly.
private struct WeakBox {
    weak var value: AnyObject?
}

final class PlayerManager: NSObject {
    static let shared = PlayerManager()

    private lazy var engine = EQEngine()
    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var localTicker: Timer?

    private(set) var queue: [Track] = []
    private(set) var index: Int = 0
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private var playingLocal = false

    private var listenerKeys: [ObjectIdentifier: WeakBox] = [:]
    private var listenerBlocks: [ObjectIdentifier: () -> Void] = [:]

    var currentTrack: Track? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    private override init() {
        super.init()
        setupRemoteCommands()
        observeInterruptions()
    }

    // MARK: - Listeners

    func listen(_ owner: AnyObject, _ block: @escaping () -> Void) {
        let key = ObjectIdentifier(owner)
        listenerKeys[key] = WeakBox(value: owner)
        listenerBlocks[key] = block
    }

    private func notifyListeners() {
        let snapshot = Array(listenerKeys)
        for (key, box) in snapshot {
            if box.value == nil {
                listenerKeys[key] = nil
                listenerBlocks[key] = nil
                continue
            }
            listenerBlocks[key]?()
        }
    }

    // MARK: - Queue control

    func load(_ tracks: [Track], at position: Int) {
        guard !tracks.isEmpty else { return }
        queue = tracks
        index = max(0, min(position, tracks.count - 1))
        playCurrent()
    }

    func jumpTo(_ position: Int) {
        guard queue.indices.contains(position) else { return }
        index = position
        playCurrent()
    }

    func next() {
        guard queue.count > 1 else { return }
        index = index + 1 < queue.count ? index + 1 : 0
        playCurrent()
    }

    func prev() {
        guard queue.count > 0 else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        index = index > 0 ? index - 1 : queue.count - 1
        playCurrent()
    }

    // MARK: - Playback

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        if playingLocal {
            engine.resume()
            isPlaying = true
        } else if let p = avPlayer {
            p.play()
            isPlaying = true
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        updateNowPlaying()
        notifyListeners()
    }

    func pause() {
        if playingLocal {
            engine.pause()
        } else {
            avPlayer?.pause()
        }
        isPlaying = false
        updateNowPlaying()
        notifyListeners()
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, max(0, duration - 0.5)))
        currentTime = clamped
        if playingLocal {
            engine.seek(to: clamped)
            if !isPlaying {
                engine.pause()
            }
        } else {
            avPlayer?.seek(
                to: CMTime(seconds: clamped, preferredTimescale: 600),
                toleranceBefore: CMTime.zero,
                toleranceAfter: CMTime.zero
            )
        }
        updateNowPlaying()
        notifyListeners()
    }

    func applyEQ() {
        engine.applySettings()
    }

    func stopAll() {
        localTicker?.invalidate()
        localTicker = nil
        if playingLocal {
            engine.stop()
            playingLocal = false
        }
        detachStreamObserver()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Internals

    private func playCurrent() {
        stopAll()
        guard let track = currentTrack else { return }
        notifyListeners()
        updateNowPlaying()

        if let local = LibraryStore.shared.localFileURL(for: track) {
            playingLocal = true
            isPlaying = true
            duration = 0
            engine.play(url: local) { [weak self] in
                self?.next()
            }
            duration = engine.totalDuration
            startTicker()
            updateNowPlaying()
            notifyListeners()
            return
        }

        switch track.source {
        case .jamendo:
            if let url = track.audio {
                startStream(url)
            } else {
                notifyListeners()
            }
        case .audius:
            let wanted = track.id
            TracksService.shared.streamURL(for: track) { [weak self] url in
                guard let self, self.currentTrack?.id == wanted else { return }
                guard let url else {
                    self.notifyListeners()
                    return
                }
                self.startStream(url)
            }
        }
    }

    private func startStream(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // continue — playback may still work
        }
        let p = AVPlayer(url: url)
        avPlayer = p
        attachTimeObserver(to: p)
        p.play()
        isPlaying = true
        UIApplication.shared.beginReceivingRemoteControlEvents()
        notifyListeners()
    }

    private func attachTimeObserver(to player: AVPlayer) {
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 2),
            queue: .main
        ) { [weak self, weak player] time in
            guard let self, let player, player === self.avPlayer else { return }
            self.currentTime = time.seconds.isFinite && time.seconds >= 0 ? time.seconds : 0
            if let item = player.currentItem {
                let d = item.duration.seconds
                if d.isFinite, d > 0 {
                    self.duration = d
                }
            }
            self.updateNowPlaying()
            self.notifyListeners()
        }
    }

    private func detachStreamObserver() {
        if let token = timeObserverToken, let old = avPlayer {
            old.removeTimeObserver(token)
        }
        timeObserverToken = nil
    }

    private func startTicker() {
        localTicker?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, self.playingLocal, self.isPlaying else { return }
            self.currentTime = self.engine.elapsed
            if self.duration == 0 {
                self.duration = self.engine.totalDuration
            }
            self.updateNowPlaying()
            self.notifyListeners()
        }
        localTicker = t
    }

    // MARK: - Lock screen / remote

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.prev()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let e = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: e.positionTime)
            return .success
        }
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if raw == AVAudioSession.InterruptionType.began.rawValue {
                self.pause()
            }
        }
    }

    private func updateNowPlaying() {
        guard let t = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: t.name,
            MPMediaItemPropertyArtist: t.artistName,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        guard let artURL = t.bestArtwork else { return }
        let wanted = t.id
        ImageLoader.shared.fetch(artURL, side: 320) { [weak self] image in
            guard let self, let image, self.currentTrack?.id == wanted else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
}

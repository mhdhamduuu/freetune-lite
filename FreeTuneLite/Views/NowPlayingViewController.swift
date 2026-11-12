import UIKit

final class NowPlayingViewController: UIViewController {
    private let closeBtn = UIButton(type: .system)
    private let art = UIImageView()
    private let titleLabel = Theme.label(17, .bold)
    private let artistLabel = Theme.label(13, color: Theme.textDim)
    private let sourceLabel = Theme.label(11, color: Theme.textFaint)
    private let slider = UISlider()
    private let timeLeft = Theme.label(11, color: Theme.textFaint)
    private let timeRight = Theme.label(11, color: Theme.textFaint)
    private let prevBtn = UIButton(type: .system)
    private let playBtn = UIButton(type: .system)
    private let nextBtn = UIButton(type: .system)
    private let queueBtn = UIButton(type: .system)
    private let eqBtn = UIButton(type: .system)
    private let downBtn = UIButton(type: .system)
    private let downLabel = Theme.label(11, color: Theme.accent)

    private var dragging = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bg

        setupViews()
        layoutViews()

        PlayerManager.shared.listen(self) { [weak self] in
            self?.refresh()
        }
        refresh()
    }

    private func setupViews() {
        closeBtn.setTitle("▼", for: .normal)
        closeBtn.setTitleColor(Theme.textDim, for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        closeBtn.addTarget(self, action: #selector(tapClose), for: .touchUpInside)

        art.contentMode = .scaleAspectFill
        art.clipsToBounds = true
        art.layer.cornerRadius = 8
        art.layer.borderWidth = 1
        art.layer.borderColor = Theme.separator.cgColor
        art.image = Theme.solid(Theme.card2, size: CGSize(width: 560, height: 560))

        titleLabel.numberOfLines = 2
        artistLabel.numberOfLines = 1
        sourceLabel.numberOfLines = 1

        slider.minimumTrackTintColor = Theme.accent
        slider.maximumTrackTintColor = Theme.separator
        slider.thumbTintColor = Theme.text
        slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderChanged), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderChanged), for: .touchUpOutside)

        transportButton(prevBtn, glyph: "⏮", size: 26, action: #selector(tapPrev))
        transportButton(playBtn, glyph: "▶", size: 34, action: #selector(tapPlay))
        transportButton(nextBtn, glyph: "⏭", size: 26, action: #selector(tapNext))

        bottomButton(queueBtn, glyph: "Queue", action: #selector(tapQueue))
        bottomButton(eqBtn, glyph: "Sound", action: #selector(tapSound))
        bottomButton(downBtn, glyph: "Download", action: #selector(tapDownload))
        downBtn.setTitleColor(Theme.accent, for: .normal)

        timeLeft.text = "0:00"
        timeRight.text = "0:00"
        timeLeft.textAlignment = .left
        timeRight.textAlignment = .right
        downLabel.textAlignment = .center
        downLabel.numberOfLines = 1
    }

    private func transportButton(_ b: UIButton, glyph: String, size: CGFloat, action: Selector) {
        b.setTitle(glyph, for: .normal)
        b.setTitleColor(Theme.text, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: size, weight: .bold)
        b.addTarget(self, action: action, for: .touchUpInside)
    }

    private func bottomButton(_ b: UIButton, glyph: String, action: Selector) {
        b.setTitle(glyph, for: .normal)
        b.setTitleColor(Theme.textDim, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        b.addTarget(self, action: action, for: .touchUpInside)
    }

    private func layoutViews() {
        let stack: [UIView] = [
            closeBtn, art, titleLabel, artistLabel, sourceLabel,
            slider, timeLeft, timeRight,
            prevBtn, playBtn, nextBtn,
            queueBtn, eqBtn, downBtn, downLabel
        ]
        stack.forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),

            art.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 18),
            art.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            art.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.78),
            art.heightAnchor.constraint(equalTo: art.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: art.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            sourceLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 3),
            sourceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            slider.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 18),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            timeLeft.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 2),
            timeLeft.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            timeRight.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 2),
            timeRight.trailingAnchor.constraint(equalTo: slider.trailingAnchor),

            playBtn.topAnchor.constraint(equalTo: timeLeft.bottomAnchor, constant: 14),
            playBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playBtn.widthAnchor.constraint(equalToConstant: 76),

            prevBtn.centerYAnchor.constraint(equalTo: playBtn.centerYAnchor),
            prevBtn.trailingAnchor.constraint(equalTo: playBtn.leadingAnchor, constant: -34),

            nextBtn.centerYAnchor.constraint(equalTo: playBtn.centerYAnchor),
            nextBtn.leadingAnchor.constraint(equalTo: playBtn.trailingAnchor, constant: 34),

            queueBtn.topAnchor.constraint(equalTo: playBtn.bottomAnchor, constant: 22),
            queueBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),

            eqBtn.topAnchor.constraint(equalTo: playBtn.bottomAnchor, constant: 22),
            eqBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            downBtn.topAnchor.constraint(equalTo: playBtn.bottomAnchor, constant: 22),
            downBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            downLabel.topAnchor.constraint(equalTo: downBtn.bottomAnchor, constant: 6),
            downLabel.centerXAnchor.constraint(equalTo: downBtn.centerXAnchor),
            downLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 90)
        ])
    }

    private func refresh() {
        let p = PlayerManager.shared
        guard let t = p.currentTrack else {
            titleLabel.text = "Nothing playing"
            artistLabel.text = "Pick a song from Music"
            sourceLabel.text = ""
            playBtn.setTitle("▶", for: .normal)
            downBtn.isHidden = true
            downLabel.isHidden = true
            return
        }
        titleLabel.text = t.name
        artistLabel.text = t.artistName
        sourceLabel.text = t.source == .audius ? "Streaming from Audius" : "Jamendo · Creative Commons"
        playBtn.setTitle(p.isPlaying ? "❚❚" : "▶", for: .normal)

        if !dragging {
            slider.maximumValue = p.duration > 0 ? Float(p.duration) : 1
            slider.value = p.duration > 0 ? Float(p.currentTime) : 0
        }
        timeLeft.text = Theme.timeString(p.currentTime)
        timeRight.text = p.duration > 0 ? "-" + Theme.timeString(p.duration - p.currentTime) : ""

        ImageLoader.shared.setImage(
            on: art,
            url: t.bestArtwork,
            side: 520,
            placeholder: Theme.solid(Theme.card2, size: CGSize(width: 560, height: 560))
        )

        if t.downloadAllowed {
            downBtn.isHidden = false
            if let progress = LibraryStore.shared.progress(for: t) {
                downLabel.isHidden = false
                downLabel.text = "\(Int(progress * 100))%"
            } else if LibraryStore.shared.isDownloaded(t) {
                downLabel.isHidden = false
                downLabel.text = "Saved ✓"
                downBtn.setTitleColor(Theme.textFaint, for: .normal)
            } else {
                downLabel.isHidden = true
                downBtn.setTitleColor(Theme.accent, for: .normal)
            }
        } else {
            downBtn.isHidden = true
            downLabel.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func tapClose() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func tapPlay() {
        PlayerManager.shared.toggle()
    }

    @objc private func tapNext() {
        PlayerManager.shared.next()
    }

    @objc private func tapPrev() {
        PlayerManager.shared.prev()
    }

    @objc private func sliderTouchDown() {
        dragging = true
    }

    @objc private func sliderChanged() {
        dragging = false
        PlayerManager.shared.seek(to: Double(slider.value))
    }

    @objc private func tapQueue() {
        present(QueueViewController(), animated: true, completion: nil)
    }

    @objc private func tapSound() {
        present(SoundViewController(), animated: true, completion: nil)
    }

    @objc private func tapDownload() {
        guard let t = PlayerManager.shared.currentTrack else { return }
        guard t.downloadAllowed else { return }
        guard !LibraryStore.shared.isDownloaded(t) else { return }
        let started = LibraryStore.shared.startDownload(
            t,
            onProgress: { [weak self] value in
                guard let self else { return }
                self.downLabel.isHidden = false
                self.downLabel.text = "\(Int(value * 100))%"
            },
            onDone: { [weak self] message in
                guard let self else { return }
                if let message {
                    let alert = UIAlertController(title: "Download failed", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                self.refresh()
            }
        )
        if started {
            downLabel.isHidden = false
            downLabel.text = "0%"
        }
    }
}

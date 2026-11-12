import UIKit

/// Small bar floating above the tab bar. Tap opens the full Now Playing screen.
final class MiniPlayerBar: UIView {
    private let art = UIImageView()
    private let titleLabel = Theme.label(13, .semibold)
    private let subLabel = Theme.label(11, color: Theme.textDim)
    private let playBtn = UIButton(type: .system)
    private let nextBtn = UIButton(type: .system)
    private let progress = UIProgressView(progressViewStyle: .bar)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.card2
        layer.cornerRadius = 10
        layer.masksToBounds = true

        art.contentMode = .scaleAspectFill
        art.clipsToBounds = true
        art.layer.cornerRadius = 5
        art.image = Theme.solid(Theme.card, size: CGSize(width: 80, height: 80))

        playBtn.setTitleColor(Theme.text, for: .normal)
        playBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        nextBtn.setTitleColor(Theme.text, for: .normal)
        nextBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        progress.progressTintColor = Theme.accent
        progress.trackTintColor = Theme.separator

        addSubview(art)
        addSubview(titleLabel)
        addSubview(subLabel)
        addSubview(playBtn)
        addSubview(nextBtn)
        addSubview(progress)

        art.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        playBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        progress.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            art.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            art.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            art.widthAnchor.constraint(equalToConstant: 40),
            art.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: art.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: playBtn.leadingAnchor, constant: -6),

            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(lessThanOrEqualTo: playBtn.leadingAnchor, constant: -6),

            playBtn.trailingAnchor.constraint(equalTo: nextBtn.leadingAnchor, constant: -14),
            playBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            playBtn.widthAnchor.constraint(equalToConstant: 34),

            nextBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            nextBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            nextBtn.widthAnchor.constraint(equalToConstant: 30),

            progress.leadingAnchor.constraint(equalTo: leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: trailingAnchor),
            progress.topAnchor.constraint(equalTo: topAnchor)
        ])

        playBtn.addTarget(self, action: #selector(tapPlay), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(tapNext), for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOpen)))

        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func observePlayer() {
        PlayerManager.shared.listen(self) { [weak self] in
            self?.refresh()
        }
    }

    private func refresh() {
        let p = PlayerManager.shared
        guard let t = p.currentTrack else {
            if !isHidden {
                UIView.animate(withDuration: 0.2) { self.alpha = 0 }
                isHidden = true
                alpha = 1
            }
            return
        }
        let wasHidden = isHidden
        isHidden = false
        if wasHidden {
            alpha = 0
            UIView.animate(withDuration: 0.25) { self.alpha = 1 }
        }
        titleLabel.text = t.name
        subLabel.text = t.artistName
        playBtn.setTitle(p.isPlaying ? "❚❚" : "▶", for: .normal)
        nextBtn.setTitle("⏭", for: .normal)
        ImageLoader.shared.setImage(
            on: art,
            url: t.bestArtwork,
            side: 40,
            placeholder: Theme.solid(Theme.card, size: CGSize(width: 80, height: 80))
        )
        progress.setProgress(p.duration > 0 ? Float(p.currentTime / p.duration) : 0, animated: false)
    }

    @objc private func tapPlay() {
        PlayerManager.shared.toggle()
    }

    @objc private func tapNext() {
        PlayerManager.shared.next()
    }

    @objc private func tapOpen() {
        guard PlayerManager.shared.currentTrack != nil,
              let window = UIApplication.shared.keyWindow,
              let root = window.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        if top is NowPlayingViewController { return }
        top.present(NowPlayingViewController(), animated: true, completion: nil)
    }
}

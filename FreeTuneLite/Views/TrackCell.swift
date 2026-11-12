import UIKit

final class TrackCell: UITableViewCell {
    static let identifier = "TrackCell"

    let art = UIImageView()
    let titleLabel = Theme.label(14, .semibold)
    let subLabel = Theme.label(12, color: Theme.textDim)
    let durLabel = Theme.label(11, color: Theme.textFaint)
    let actionButton = UIButton(type: .system)
    let progressLabel = Theme.label(10, .bold, color: Theme.accent)
    var onDownload: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        art.contentMode = .scaleAspectFill
        art.clipsToBounds = true
        art.layer.cornerRadius = 5

        actionButton.setTitleColor(Theme.accent, for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)

        progressLabel.textAlignment = .right
        progressLabel.numberOfLines = 1

        titleLabel.numberOfLines = 1
        subLabel.numberOfLines = 1
        durLabel.textAlignment = .right

        contentView.addSubview(art)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(durLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(progressLabel)

        for v in [art, titleLabel, subLabel, durLabel, actionButton, progressLabel] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            art.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            art.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            art.widthAnchor.constraint(equalToConstant: 46),
            art.heightAnchor.constraint(equalToConstant: 46),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: art.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: durLabel.leadingAnchor, constant: -8),

            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(lessThanOrEqualTo: durLabel.leadingAnchor, constant: -8),
            subLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            durLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -8),
            durLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),

            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 34),

            progressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            progressLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressLabel.widthAnchor.constraint(equalToConstant: 44)
        ])

        actionButton.addTarget(self, action: #selector(tapDownload), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageLoader.shared.setImage(on: art, url: nil, side: 46, placeholder: nil)
        onDownload = nil
        progressLabel.isHidden = true
        actionButton.isHidden = true
    }

    func bind(
        _ track: Track,
        downloadProgress: Double?,
        downloaded: Bool,
        onDownload: @escaping () -> Void
    ) {
        self.onDownload = onDownload
        titleLabel.text = track.name
        let src = track.source == .audius ? "Audius" : "Jamendo"
        subLabel.text = "\(track.artistName)  ·  \(src)"
        durLabel.text = track.duration.map { Theme.timeString(Double($0)) } ?? ""

        actionButton.isHidden = true
        progressLabel.isHidden = true

        if let p = downloadProgress {
            progressLabel.isHidden = false
            progressLabel.text = "\(Int(p * 100))%"
        } else if downloaded {
            actionButton.isHidden = false
            actionButton.setTitle("✓", for: .normal)
            actionButton.setTitleColor(Theme.textFaint, for: .normal)
        } else if track.downloadAllowed {
            actionButton.isHidden = false
            actionButton.setTitle("⬇", for: .normal)
            actionButton.setTitleColor(Theme.accent, for: .normal)
        }

        ImageLoader.shared.setImage(
            on: art,
            url: track.bestArtwork,
            side: 46,
            placeholder: Theme.solid(Theme.card2, size: CGSize(width: 92, height: 92))
        )
    }

    func showProgress(_ value: Double) {
        progressLabel.isHidden = false
        progressLabel.text = "\(Int(value * 100))%"
        actionButton.isHidden = true
    }

    @objc private func tapDownload() {
        onDownload?()
    }
}

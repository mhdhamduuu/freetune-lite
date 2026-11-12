import UIKit

final class DownloadsViewController: UIViewController {
    private let table = UITableView(frame: .zero, style: .plain)
    private let statusLabel = Theme.label(13, color: Theme.textDim)
    private let sizeLabel = Theme.label(11, color: Theme.textFaint)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Downloads"
        view.backgroundColor = Theme.bg

        table.backgroundColor = .clear
        table.separatorColor = Theme.separator
        table.rowHeight = 64
        table.dataSource = self
        table.delegate = self
        table.register(TrackCell.self, forCellReuseIdentifier: TrackCell.identifier)
        table.contentInsetAdjustmentBehavior = .never
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)

        statusLabel.numberOfLines = 0
        sizeLabel.numberOfLines = 1

        view.addSubview(table)
        view.addSubview(statusLabel)
        view.addSubview(sizeLabel)
        table.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sizeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            sizeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sizeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),

            table.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        PlayerManager.shared.listen(self) { [weak self] in
            self?.table.reloadData()
        }

        NotificationCenter.default.addObserver(
            forName: LibraryStore.downloadsChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadData()
        }

        reloadData()
    }

    private func reloadData() {
        let list = LibraryStore.shared.downloads
        let bytes = LibraryStore.shared.totalBytes()
        sizeLabel.text = list.isEmpty
            ? ""
            : "\(list.count) song\(list.count == 1 ? "" : "s")  ·  \(String(format: "%.1f", Double(bytes) / 1_048_576)) MB offline"
        statusLabel.text = list.isEmpty
            ? "No downloads yet.\nTap ⬇ next to any Jamendo song in the Music tab to save it offline."
            : ""
        table.reloadData()
    }
}

extension DownloadsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LibraryStore.shared.downloads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackCell.identifier, for: indexPath) as? TrackCell else {
            return UITableViewCell()
        }
        let entry = LibraryStore.shared.downloads[indexPath.row]
        cell.bind(
            entry.track,
            downloadProgress: nil,
            downloaded: true,
            onDownload: {}
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entries = LibraryStore.shared.downloads
        let tracks = entries.map { $0.track }
        PlayerManager.shared.load(tracks, at: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        let entry = LibraryStore.shared.downloads[indexPath.row]
        LibraryStore.shared.remove(entry)
        reloadData()
    }
}

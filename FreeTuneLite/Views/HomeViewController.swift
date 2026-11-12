import UIKit

final class HomeViewController: UIViewController {
    enum Feed: Equatable {
        case audiusTrending(time: String?)
        case searchAll(String)
    }

    struct Chip {
        let title: String
        let feed: Feed
    }

    private let searchBar = UISearchBar()
    private let chipScroll = UIScrollView()
    private let chipRow = UIStackView()
    private let table = UITableView(frame: .zero, style: .plain)
    private let statusLabel = Theme.label(13, color: Theme.textDim)

    private var feed: Feed = .audiusTrending(time: "week")
    private var tracks: [Track] = []
    private var offset = 0
    private var loading = false
    private var hasMore = true
    private let pageSize = 30

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FreeTune"
        view.backgroundColor = Theme.bg
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setupSearchBar()
        setupChips()
        setupTable()
        layoutUI()

        loadPage(reset: true)
    }

    // MARK: - UI setup

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.barStyle = .black
        searchBar.barTintColor = Theme.bg
        searchBar.backgroundColor = Theme.bg
        searchBar.isTranslucent = false
        searchBar.placeholder = "Search songs, artists, Malayalam…"
        searchBar.returnKeyType = .search
        searchBar.tintColor = Theme.accent
        let tf = searchBar.textField
        tf?.textColor = Theme.text
        tf?.backgroundColor = Theme.card2
    }

    private func setupChips() {
        chipScroll.showsHorizontalScrollIndicator = false
        chipScroll.alwaysBounceHorizontal = true
        chipScroll.backgroundColor = .clear
        chipScroll.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        chipRow.axis = .horizontal
        chipRow.spacing = 8
        chipRow.alignment = .center
        chipRow.distribution = .fill
        chipRow.backgroundColor = .clear

        chipScroll.addSubview(chipRow)
        chipRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chipRow.topAnchor.constraint(equalTo: chipScroll.topAnchor),
            chipRow.bottomAnchor.constraint(equalTo: chipScroll.bottomAnchor),
            chipRow.leadingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.leadingAnchor),
            chipRow.trailingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.trailingAnchor),
            chipRow.heightAnchor.constraint(equalTo: chipScroll.heightAnchor)
        ])

        rebuildChips()
    }

    private func setupTable() {
        table.backgroundColor = .clear
        table.separatorColor = Theme.separator
        table.rowHeight = 64
        table.keyboardDismissMode = .onDrag
        table.dataSource = self
        table.delegate = self
        table.register(TrackCell.self, forCellReuseIdentifier: TrackCell.identifier)
        table.contentInsetAdjustmentBehavior = .never
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
        if #available(iOS 10.0, *) {
            let rc = UIRefreshControl()
            rc.tintColor = Theme.accent
            rc.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
            table.refreshControl = rc
        }
    }

    private func layoutUI() {
        view.addSubview(searchBar)
        view.addSubview(chipScroll)
        view.addSubview(statusLabel)
        view.addSubview(table)

        for v in [searchBar, chipScroll, statusLabel, table] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),

            chipScroll.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            chipScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipScroll.heightAnchor.constraint(equalToConstant: 36),

            statusLabel.topAnchor.constraint(equalTo: chipScroll.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(equalToConstant: 18),

            table.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Chips

    private var chips: [Chip] {
        if case .searchAll = feed {
            return [
                Chip(title: "✕  Clear search", feed: .audiusTrending(time: "week")),
                Chip(title: "Malayalam", feed: .searchAll("malayalam")),
                Chip(title: "Kerala", feed: .searchAll("kerala")),
                Chip(title: "Devotional", feed: .searchAll("devotional")),
                Chip(title: "Tamil", feed: .searchAll("tamil"))
            ]
        }
        return [
            Chip(title: "New This Week", feed: .audiusTrending(time: "week")),
            Chip(title: "New This Month", feed: .audiusTrending(time: "month")),
            Chip(title: "New This Year", feed: .audiusTrending(time: "year")),
            Chip(title: "All-Time Top", feed: .audiusTrending(time: "allTime")),
            Chip(title: "Malayalam", feed: .searchAll("malayalam")),
            Chip(title: "Kerala", feed: .searchAll("kerala")),
            Chip(title: "Devotional", feed: .searchAll("devotional")),
            Chip(title: "Tamil", feed: .searchAll("tamil")),
            Chip(title: "Chill", feed: .searchAll("chill")),
            Chip(title: "Hip-Hop", feed: .searchAll("hip hop"))
        ]
    }

    private func rebuildChips() {
        chipRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, chip) in chips.enumerated() {
            let active = chip.feed == feed
            let b = UIButton(type: .system)
            b.tag = i
            b.setTitle(chip.title, for: .normal)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            b.setTitleColor(active ? Theme.text : Theme.textDim, for: .normal)
            b.backgroundColor = active ? Theme.accent : Theme.card2
            b.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
            b.layer.cornerRadius = 15
            b.layer.masksToBounds = true
            b.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipRow.addArrangedSubview(b)
        }
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard chips.indices.contains(sender.tag) else { return }
        let chip = chips[sender.tag]
        searchBar.text = nil
        searchBar.resignFirstResponder()
        feed = chip.feed
        rebuildChips()
        loadPage(reset: true)
    }

    // MARK: - Data

    private func setStatus(_ text: String) {
        statusLabel.text = text
    }

    private func message(for error: Error) -> String {
        if let api = error as? APIError {
            return api.errorDescription ?? "Something went wrong"
        }
        return "No internet connection — check WiFi/data"
    }

    private func loadPage(reset: Bool) {
        guard !loading else { return }
        loading = true
        if reset { setStatus("Loading…") }

        let limit = pageSize
        let off = reset ? 0 : offset

        let handler: ([Track], Error?) -> Void = { [weak self] newTracks, error in
            guard let self else { return }
            self.loading = false
            self.table.refreshControl?.endRefreshing()
            if let error {
                if reset {
                    self.tracks = []
                    self.setStatus(self.message(for: error))
                } else {
                    self.hasMore = false
                }
                self.table.reloadData()
                return
            }
            if reset {
                self.tracks = newTracks
            } else {
                self.tracks += newTracks
            }
            self.offset = off + newTracks.count
            self.hasMore = newTracks.count >= limit
            self.setStatus(self.tracks.isEmpty ? "Nothing here yet — try another chip 🔍" : "")
            self.table.reloadData()
        }

        switch feed {
        case .audiusTrending(let time):
            TracksService.shared.audiusTrending(
                time: time,
                genre: nil,
                limit: limit,
                offset: off,
                completion: handler
            )
        case .searchAll(let query):
            searchBoth(query, limit: limit, offset: off, completion: handler)
        }
    }

    private func searchBoth(
        _ query: String,
        limit: Int,
        offset: Int,
        completion: @escaping ([Track], Error?) -> Void
    ) {
        let group = DispatchGroup()
        var audius: [Track] = []
        var jamendo: [Track] = []
        var audiusError: Error?

        group.enter()
        TracksService.shared.audiusSearch(query, limit: limit, offset: offset) { result, error in
            audius = result
            audiusError = error
            group.leave()
        }

        if SettingsStore.shared.hasJamendoKey {
            group.enter()
            TracksService.shared.jamendoSearch(query, limit: limit, offset: offset) { result, _ in
                jamendo = result
                group.leave()
            }
        }

        group.notify(queue: .main) {
            var merged: [Track] = []
            let n = max(audius.count, jamendo.count)
            for i in 0..<n {
                if i < audius.count { merged.append(audius[i]) }
                if i < jamendo.count { merged.append(jamendo[i]) }
            }
            if audius.isEmpty && jamendo.isEmpty {
                completion([], audiusError)
            } else {
                completion(merged, nil)
            }
        }
    }

    @objc private func pulledToRefresh() {
        offset = 0
        hasMore = true
        loadPage(reset: true)
    }

    private func openDownload(_ track: Track) {
        let started = LibraryStore.shared.startDownload(
            track,
            onProgress: { [weak self] value in
                guard let self else { return }
                guard let row = self.tracks.firstIndex(where: { $0.id == track.id }) else { return }
                if let cell = self.table.cellForRow(at: IndexPath(row: row, section: 0)) as? TrackCell {
                    cell.showProgress(value)
                }
            },
            onDone: { [weak self] message in
                guard let self else { return }
                if let message {
                    let alert = UIAlertController(title: "Download failed", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                self.table.reloadData()
            }
        )
        if started {
            if let row = tracks.firstIndex(where: { $0.id == track.id }),
               let cell = table.cellForRow(at: IndexPath(row: row, section: 0)) as? TrackCell {
                cell.showProgress(0)
            }
        }
    }

    private func openNowPlaying() {
        guard PlayerManager.shared.currentTrack != nil else { return }
        present(NowPlayingViewController(), animated: true, completion: nil)
    }
}

// MARK: - Table

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackCell.identifier, for: indexPath) as? TrackCell else {
            return UITableViewCell()
        }
        let track = tracks[indexPath.row]
        cell.bind(
            track,
            downloadProgress: LibraryStore.shared.progress(for: track),
            downloaded: LibraryStore.shared.isDownloaded(track),
            onDownload: { [weak self] in
                self?.openDownload(track)
            }
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerManager.shared.load(tracks, at: indexPath.row)
        openNowPlaying()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === table, hasMore, !loading, !tracks.isEmpty else { return }
        let bottom = scrollView.contentOffset.y + scrollView.frame.height
        if bottom > scrollView.contentSize.height - scrollView.frame.height * 2 {
            loadPage(reset: false)
        }
    }
}

// MARK: - Search

extension HomeViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        searchBar.resignFirstResponder()
        feed = .searchAll(query)
        rebuildChips()
        loadPage(reset: true)
    }
}

// MARK: - UISearchBar internals (iOS 12-safe)

private extension UISearchBar {
    var textField: UITextField? {
        value(forKey: "searchField") as? UITextField
    }
}

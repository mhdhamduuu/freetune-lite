import Foundation

final class LibraryStore: NSObject {
    static let shared = LibraryStore()

    static let downloadsChangedNotification = Notification.Name("lite.downloadsChanged")

    private let d = UserDefaults.standard
    private let listKey = "lite.downloads"

    private(set) var downloads: [DownloadedTrack] = []

    private var activeProgress: [String: Double] = [:]
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var activeSessions: [String: URLSession] = [:]
    private var delegates: [String: DownloadDelegate] = [:]

    private override init() {
        super.init()
        reload()
    }

    func reload() {
        if let data = d.data(forKey: listKey),
           let list = try? JSONDecoder().decode([DownloadedTrack].self, from: data) {
            downloads = list
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(downloads) {
            d.set(data, forKey: listKey)
        }
        NotificationCenter.default.post(
            name: LibraryStore.downloadsChangedNotification,
            object: nil
        )
    }

    // MARK: - Files

    func folderURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Downloads", isDirectory: true)
    }

    func localFileURL(for track: Track) -> URL? {
        guard let entry = downloads.first(where: { $0.track.id == track.id }) else { return nil }
        let url = folderURL().appendingPathComponent(entry.fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func isDownloaded(_ track: Track) -> Bool {
        localFileURL(for: track) != nil
    }

    func contains(_ track: Track) -> Bool {
        downloads.contains { $0.track.id == track.id }
    }

    func progress(for track: Track) -> Double? {
        activeProgress[track.id]
    }

    func totalBytes() -> Int64 {
        downloads.reduce(0) { $0 + $1.fileSize }
    }

    // MARK: - Download

    @discardableResult
    func startDownload(
        _ track: Track,
        onProgress: @escaping (Double) -> Void,
        onDone: @escaping (String?) -> Void
    ) -> Bool {
        guard let remote = track.audioDownload ?? track.audio else { return false }
        guard !contains(track) else { return false }
        guard activeProgress[track.id] == nil else { return false }

        let id = track.id
        let delegate = DownloadDelegate(
            onProgress: { [weak self] progress in
                self?.activeProgress[id] = progress
                onProgress(progress)
            },
            onFinished: { [weak self] location, message in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.activeProgress[id] = nil
                    self.activeTasks[id] = nil
                    self.activeSessions[id]?.finishTasksAndInvalidate()
                    self.activeSessions[id] = nil
                    self.delegates[id] = nil
                    if let message {
                        onDone(message)
                        return
                    }
                    guard let location else {
                        onDone("Download failed")
                        return
                    }
                    do {
                        let fm = FileManager.default
                        try fm.createDirectory(at: self.folderURL(), withIntermediateDirectories: true, attributes: nil)
                        let ext = remote.pathExtension.isEmpty ? "mp3" : remote.pathExtension
                        let fileName = UUID().uuidString + "." + ext
                        let dest = self.folderURL().appendingPathComponent(fileName)
                        try fm.moveItem(at: location, to: dest)
                        let attrs = try? fm.attributesOfItem(atPath: dest.path)
                        let size = (attrs?[.size] as? Int64) ?? 0
                        let entry = DownloadedTrack(track: track, fileName: fileName, downloadedAt: Date(), fileSize: size)
                        self.downloads.insert(entry, at: 0)
                        self.persist()
                        onDone(nil)
                    } catch {
                        onDone(error.localizedDescription)
                    }
                }
            }
        )

        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(with: remote)
        activeProgress[id] = 0
        activeTasks[id] = task
        activeSessions[id] = session
        delegates[id] = delegate
        task.resume()
        return true
    }

    func cancelDownload(_ track: Track) {
        let id = track.id
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        activeProgress[id] = nil
        activeSessions[id]?.finishTasksAndInvalidate()
        activeSessions[id] = nil
        delegates[id] = nil
    }

    func remove(_ entry: DownloadedTrack) {
        downloads.removeAll { $0.track.id == entry.track.id }
        let url = folderURL().appendingPathComponent(entry.fileName)
        try? FileManager.default.removeItem(at: url)
        persist()
    }
}

// MARK: - Download delegate

final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let onProgress: (Double) -> Void
    private let onFinished: (URL?, String?) -> Void

    init(onProgress: @escaping (Double) -> Void, onFinished: @escaping (URL?, String?) -> Void) {
        self.onProgress = onProgress
        self.onFinished = onFinished
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        onProgress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        onFinished(location, nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            onFinished(nil, error.localizedDescription)
        }
    }
}

import Foundation

enum APIError: LocalizedError {
    case badResponse
    case noHost
    case missingKey

    var errorDescription: String? {
        switch self {
        case .badResponse: return "The music service did not answer. Try again."
        case .noHost: return "Could not reach the Audius network."
        case .missingKey: return "Add your free Jamendo key in Settings."
        }
    }
}

/// All networking is callback-based: Swift Concurrency (async/await) does not
/// exist on iOS 12, so FreeTune Lite never uses it.
final class TracksService {
    static let shared = TracksService()

    private var audiusHost: String?
    private var fetchingHost = false
    private var pendingHostCallbacks: [(String?) -> Void] = []

    private init() {}

    // MARK: - Audius

    func audiusTrending(
        time: String?,
        genre: String?,
        limit: Int,
        offset: Int,
        completion: @escaping ([Track], Error?) -> Void
    ) {
        resolveHost { host in
            guard let host else {
                completion([], APIError.noHost)
                return
            }
            var comps = URLComponents(string: host + "/v1/tracks/trending")
            var items = [
                URLQueryItem(name: "app_name", value: "FreeTuneLite"),
                URLQueryItem(name: "limit", value: String(max(1, limit))),
                URLQueryItem(name: "offset", value: String(max(0, offset)))
            ]
            if let time, !time.isEmpty {
                items.append(URLQueryItem(name: "time", value: time))
            }
            if let genre, !genre.isEmpty {
                items.append(URLQueryItem(name: "genre", value: genre))
            }
            comps?.queryItems = items
            guard let url = comps?.url else {
                completion([], APIError.badResponse)
                return
            }
            self.getJSON(url, type: AudiusPage.self) { page, error in
                let tracks = (page?.data ?? []).map(Track.audius)
                completion(tracks, error)
            }
        }
    }

    func audiusSearch(
        _ query: String,
        limit: Int,
        offset: Int,
        completion: @escaping ([Track], Error?) -> Void
    ) {
        resolveHost { host in
            guard let host else {
                completion([], APIError.noHost)
                return
            }
            var comps = URLComponents(string: host + "/v1/tracks/search")
            comps?.queryItems = [
                URLQueryItem(name: "app_name", value: "FreeTuneLite"),
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "limit", value: String(max(1, limit))),
                URLQueryItem(name: "offset", value: String(max(0, offset)))
            ]
            guard let url = comps?.url else {
                completion([], APIError.badResponse)
                return
            }
            self.getJSON(url, type: AudiusPage.self) { page, error in
                let tracks = (page?.data ?? []).map(Track.audius)
                completion(tracks, error)
            }
        }
    }

    /// Streaming URL for an Audius track (their streams are host-relative).
    func streamURL(for track: Track, completion: @escaping (URL?) -> Void) {
        if let direct = track.audio {
            completion(direct)
            return
        }
        guard track.source == .audius, track.id.hasPrefix("au-") else {
            completion(nil)
            return
        }
        let rawID = String(track.id.dropFirst(3))
        resolveHost { host in
            guard let host else {
                completion(nil)
                return
            }
            completion(URL(string: host + "/v1/tracks/\(rawID)/stream?app_name=FreeTuneLite"))
        }
    }

    private func resolveHost(_ completion: @escaping (String?) -> Void) {
        if let host = audiusHost {
            completion(host)
            return
        }
        pendingHostCallbacks.append(completion)
        if fetchingHost { return }
        fetchingHost = true

        struct HostPage: Decodable {
            let data: [String]?
        }

        guard let url = URL(string: "https://api.audius.co") else {
            fetchingHost = false
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            let hosts = (try? JSONDecoder().decode(HostPage.self, from: data ?? Data()))?.data ?? []
            let pick = hosts.randomElement()
            DispatchQueue.main.async {
                self.fetchingHost = false
                if let pick {
                    self.audiusHost = pick
                }
                let all = self.pendingHostCallbacks
                self.pendingHostCallbacks.removeAll()
                all.forEach { $0(self.audiusHost) }
            }
        }.resume()
    }

    // MARK: - Jamendo

    func jamendo(
        order: String,
        tag: String?,
        limit: Int,
        offset: Int,
        completion: @escaping ([Track], Error?) -> Void
    ) {
        let key = SettingsStore.shared.jamendoKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            completion([], APIError.missingKey)
            return
        }
        var comps = URLComponents(string: "https://api.jamendo.com/v3.0/tracks")
        var items = [
            URLQueryItem(name: "client_id", value: key),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "audioformat", value: "mp32")
        ]
        if let tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "tags", value: tag))
        }
        comps?.queryItems = items
        guard let url = comps?.url else {
            completion([], APIError.badResponse)
            return
        }
        getJSON(url, type: JamendoPage.self) { page, error in
            let tracks = (page?.results ?? []).map(Track.jamendo)
            completion(tracks, error)
        }
    }

    func jamendoSearch(
        _ query: String,
        limit: Int,
        offset: Int,
        completion: @escaping ([Track], Error?) -> Void
    ) {
        let key = SettingsStore.shared.jamendoKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            completion([], APIError.missingKey)
            return
        }
        var comps = URLComponents(string: "https://api.jamendo.com/v3.0/tracks")
        comps?.queryItems = [
            URLQueryItem(name: "client_id", value: key),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "order", value: "popularity_total"),
            URLQueryItem(name: "audioformat", value: "mp32")
        ]
        guard let url = comps?.url else {
            completion([], APIError.badResponse)
            return
        }
        getJSON(url, type: JamendoPage.self) { page, error in
            let tracks = (page?.results ?? []).map(Track.jamendo)
            completion(tracks, error)
        }
    }

    // MARK: - Generic JSON

    private func getJSON<T: Decodable>(
        _ url: URL,
        type: T.Type,
        completion: @escaping (T?, Error?) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let error {
                    completion(nil, error)
                    return
                }
                guard let data else {
                    completion(nil, APIError.badResponse)
                    return
                }
                do {
                    completion(try JSONDecoder().decode(T.self, from: data), nil)
                } catch {
                    completion(nil, error)
                }
            }
        }.resume()
    }
}

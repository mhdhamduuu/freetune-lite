import Foundation

// MARK: - Sources

enum TrackSource: String, Codable, Hashable {
    case jamendo
    case audius
}

// MARK: - Universal track

struct Track: Codable, Hashable {
    let id: String
    let source: TrackSource
    let name: String
    let artistName: String
    let albumName: String?
    let duration: Int?
    let image: URL?
    let albumImage: URL?
    let audio: URL?
    let audioDownload: URL?
    let audioDownloadAllowed: Bool
    let licenseURL: String?

    var bestArtwork: URL? { albumImage ?? image }
    var downloadAllowed: Bool { audioDownloadAllowed && audioDownload != nil }
}

// MARK: - Jamendo raw wire format

struct JamendoHeaders: Decodable {
    let status: String?
    let code: Int?
}

struct JamendoRawTrack: Decodable, Hashable {
    let id: String
    let name: String
    let duration: Int?
    let artistName: String
    let artistImage: URL?
    let albumName: String?
    let albumImage: URL?
    let image: URL?
    let audio: URL?
    let audioDownload: URL?
    let audioDownloadAllowed: Bool?
    let licenseURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, duration, audio, image
        case artistName = "artist_name"
        case artistImage = "artist_image"
        case albumName = "album_name"
        case albumImage = "album_image"
        case audioDownload = "audiodownload"
        case audioDownloadAllowed = "audiodownload_allowed"
        case licenseURL = "license_ccurl"
    }
}

struct JamendoPage: Decodable {
    let headers: JamendoHeaders?
    let results: [JamendoRawTrack]?
}

// MARK: - Audius raw wire format

struct AudiusRawTrack: Decodable, Hashable {
    let id: String
    let title: String
    let duration: Int?
    let genre: String?
    let playCount: Int?
    let artwork: AudiusArtwork?
    let user: AudiusUser?

    struct AudiusArtwork: Decodable, Hashable {
        let small: URL?
        let medium: URL?
        let large: URL?

        enum CodingKeys: String, CodingKey {
            case small = "150x150"
            case medium = "480x480"
            case large = "1000x1000"
        }

        var best: URL? { medium ?? large ?? small }
    }

    struct AudiusUser: Decodable, Hashable {
        let name: String?
    }
}

struct AudiusPage: Decodable {
    let data: [AudiusRawTrack]?
}

// MARK: - Mappers

extension Track {
    static func jamendo(_ raw: JamendoRawTrack) -> Track {
        Track(
            id: "jm-\(raw.id)",
            source: .jamendo,
            name: raw.name,
            artistName: raw.artistName,
            albumName: raw.albumName,
            duration: raw.duration,
            image: raw.image,
            albumImage: raw.albumImage,
            audio: raw.audio,
            audioDownload: raw.audioDownload,
            audioDownloadAllowed: raw.audioDownloadAllowed ?? true,
            licenseURL: raw.licenseURL
        )
    }

    static func audius(_ raw: AudiusRawTrack) -> Track {
        Track(
            id: "au-\(raw.id)",
            source: .audius,
            name: raw.title,
            artistName: raw.user?.name ?? "Unknown artist",
            albumName: raw.genre,
            duration: raw.duration,
            image: nil,
            albumImage: raw.artwork?.best,
            audio: nil,
            audioDownload: nil,
            audioDownloadAllowed: false,
            licenseURL: nil
        )
    }
}

// MARK: - Downloaded track

struct DownloadedTrack: Codable, Hashable {
    let track: Track
    let fileName: String
    let downloadedAt: Date
    let fileSize: Int64
}

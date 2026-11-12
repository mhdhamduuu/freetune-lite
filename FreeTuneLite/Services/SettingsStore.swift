import Foundation

final class SettingsStore {
    static let shared = SettingsStore()

    private let d = UserDefaults.standard

    private enum Keys {
        static let jamendoKey = "lite.jamendoKey"
        static let eqOn = "lite.eqOn"
        static let eqGains = "lite.eqGains"
        static let reverbOn = "lite.reverbOn"
    }

    var jamendoKey: String {
        get { d.string(forKey: Keys.jamendoKey) ?? "" }
        set { d.set(newValue, forKey: Keys.jamendoKey) }
    }

    var hasJamendoKey: Bool {
        jamendoKey.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }

    var eqOn: Bool {
        get { d.object(forKey: Keys.eqOn) == nil ? true : d.bool(forKey: Keys.eqOn) }
        set { d.set(newValue, forKey: Keys.eqOn) }
    }

    var eqGains: [Float] {
        get {
            if let raw = d.array(forKey: Keys.eqGains) as? [Float], raw.count == 5 {
                return raw
            }
            return [0, 0, 0, 0, 0]
        }
        set {
            d.set(Array(newValue.prefix(5)), forKey: Keys.eqGains)
        }
    }

    var reverbOn: Bool {
        get { d.bool(forKey: Keys.reverbOn) }
        set { d.set(newValue, forKey: Keys.reverbOn) }
    }
}

import UIKit

final class SettingsViewController: UIViewController {
    private let keyField = UITextField()
    private let statusLabel = Theme.label(12, color: Theme.textFaint)
    private let aboutLabel = Theme.label(12, color: Theme.textDim)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = Theme.bg

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

        let jamendoTitle = Theme.label(15, .bold)
        jamendoTitle.text = "Jamendo (offline downloads)"
        let jamendoInfo = Theme.label(12, color: Theme.textDim)
        jamendoInfo.text = "Jamendo songs are Creative Commons — legal to download. One free step: register at dev.jamendo.com, copy your Client ID, paste it here."
        jamendoInfo.numberOfLines = 0

        keyField.backgroundColor = Theme.card2
        keyField.textColor = Theme.text
        keyField.font = UIFont.systemFont(ofSize: 14)
        keyField.placeholder = "Paste your Jamendo Client ID"
        keyField.text = SettingsStore.shared.jamendoKey
        keyField.layer.cornerRadius = 10
        keyField.layer.masksToBounds = true
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        keyField.leftView = pad
        keyField.leftViewMode = .always
        keyField.delegate = self
        keyField.autocorrectionType = .no
        keyField.autocapitalizationType = .none

        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save key", for: .normal)
        saveBtn.setTitleColor(Theme.text, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        saveBtn.backgroundColor = Theme.accent
        saveBtn.layer.cornerRadius = 10
        saveBtn.layer.masksToBounds = true
        saveBtn.addTarget(self, action: #selector(tapSave), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        updateStatus()

        let cacheBtn = UIButton(type: .system)
        cacheBtn.setTitle("Clear artwork cache", for: .normal)
        cacheBtn.setTitleColor(Theme.accent, for: .normal)
        cacheBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        cacheBtn.addTarget(self, action: #selector(tapClearCache), for: .touchUpInside)

        aboutLabel.numberOfLines = 0
        aboutLabel.text = """
        FreeTune Lite \(version) · iOS 12+
        Free, ad-free, no account needed.

        Music sources (100% legal):
        • Audius — artist-authorized streaming network
        • Jamendo — Creative Commons catalog (with your free key)

        Original Bollywood/Mollywood film songs are not included —
        those are label-owned and not on any free legal API.
        """

        let stack = UIStackView(arrangedSubviews: [
            jamendoTitle, jamendoInfo, keyField, saveBtn, statusLabel,
            spacer(20),
            section("Storage"), cacheBtn,
            spacer(20),
            section("About"), aboutLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -30),
            keyField.heightAnchor.constraint(equalToConstant: 44),
            saveBtn.heightAnchor.constraint(equalToConstant: 42)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackground))
        scroll.addGestureRecognizer(tap)
    }

    @objc private func tapBackground() {
        view.endEditing(true)
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func section(_ text: String) -> UILabel {
        let l = Theme.label(15, .bold)
        l.text = text
        return l
    }

    private func updateStatus() {
        statusLabel.text = SettingsStore.shared.hasJamendoKey
            ? "✓ Key saved — Jamendo browsing + downloads are on."
            : "No key yet — Jamendo songs are hidden until you add one."
    }

    @objc private func tapSave() {
        keyField.resignFirstResponder()
        let value = (keyField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        SettingsStore.shared.jamendoKey = value
        updateStatus()
        let alert = UIAlertController(
            title: SettingsStore.shared.hasJamendoKey ? "Saved ✓" : "Cleared",
            message: SettingsStore.shared.hasJamendoKey
                ? "Jamendo is now part of your catalog."
                : "Jamendo disabled. Audius still works fully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func tapClearCache() {
        ImageLoader.shared.clearCache()
        let alert = UIAlertController(title: "Cleared ✓", message: "Artwork cache is empty.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

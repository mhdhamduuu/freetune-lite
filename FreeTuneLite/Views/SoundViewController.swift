import UIKit

final class SoundViewController: UIViewController {
    private let eqSwitch = UISwitch()
    private let reverbSwitch = UISwitch()
    private var gainSliders: [UISlider] = []
    private let gainLabels: [(String, String)] = [
        ("Bass", "60 Hz"),
        ("Low", "230 Hz"),
        ("Mid", "910 Hz"),
        ("High", "3.6 kHz"),
        ("Air", "14 kHz")
    ]
    private let noteLabel = Theme.label(12, color: Theme.textDim)
    private let statusLabel = Theme.label(12, color: Theme.textFaint)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sound"
        view.backgroundColor = Theme.bg

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(tapDone)
        )

        let s = SettingsStore.shared
        eqSwitch.isOn = s.eqOn
        eqSwitch.onTintColor = Theme.accent
        eqSwitch.addTarget(self, action: #selector(controlChanged), for: .valueChanged)

        reverbSwitch.isOn = s.reverbOn
        reverbSwitch.onTintColor = Theme.accent
        reverbSwitch.addTarget(self, action: #selector(controlChanged), for: .valueChanged)

        for i in 0..<5 {
            let slider = UISlider()
            slider.minimumValue = -12
            slider.maximumValue = 12
            slider.value = s.eqGains[i]
            slider.minimumTrackTintColor = Theme.accent
            slider.maximumTrackTintColor = Theme.separator
            slider.thumbTintColor = Theme.text
            slider.tag = i
            slider.addTarget(self, action: #selector(gainChanged(_:)), for: .valueChanged)
            gainSliders.append(slider)
        }

        noteLabel.text = "EQ and ambience apply to downloaded songs.\nStreams play through the native player for battery life."
        noteLabel.numberOfLines = 0

        buildLayout()
        updateStatus()
    }

    private func buildLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        var rows: [UIView] = []

        rows.append(sectionHeader("Equalizer"))
        rows.append(row("EQ On", eqSwitch))
        for (i, slider) in gainSliders.enumerated() {
            let title = gainLabels[i].0 + "  (" + gainLabels[i].1 + ")"
            rows.append(row(title, slider))
        }

        rows.append(sectionHeader("Ambience"))
        rows.append(row("Concert-hall reverb", reverbSwitch))

        rows.append(sectionHeader("Note"))
        rows.append(noteLabel)
        rows.append(statusLabel)

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -30)
        ])
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = Theme.label(15, .bold, color: Theme.text)
        l.text = text
        return l
    }

    private func row(_ title: String, _ control: UIView) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true

        let l = Theme.label(14, color: Theme.text)
        l.text = title
        l.numberOfLines = 0

        container.addSubview(l)
        container.addSubview(control)
        l.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            l.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            l.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -10),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            control.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            control.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 10),
            control.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -10),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
        return container
    }

    private func updateStatus() {
        let keyOk = SettingsStore.shared.hasJamendoKey
        statusLabel.text = keyOk
            ? "Jamendo key set ✓ — downloads enabled."
            : "Tip: add your free Jamendo key in Settings to enable offline downloads."
    }

    @objc private func gainChanged(_ sender: UISlider) {
        var gains = SettingsStore.shared.eqGains
        if sender.tag < gains.count {
            gains[sender.tag] = sender.value
        }
        SettingsStore.shared.eqGains = gains
        PlayerManager.shared.applyEQ()
    }

    @objc private func controlChanged() {
        SettingsStore.shared.eqOn = eqSwitch.isOn
        SettingsStore.shared.reverbOn = reverbSwitch.isOn
        PlayerManager.shared.applyEQ()
    }

    @objc private func tapDone() {
        dismiss(animated: true, completion: nil)
    }
}

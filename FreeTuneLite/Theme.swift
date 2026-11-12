import UIKit

enum Theme {
    static let bg = UIColor(red: 0.043, green: 0.043, blue: 0.06, alpha: 1)
    static let card = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)
    static let card2 = UIColor(red: 0.14, green: 0.14, blue: 0.17, alpha: 1)
    static let text = UIColor.white
    static let textDim = UIColor(white: 1.0, alpha: 0.55)
    static let textFaint = UIColor(white: 1.0, alpha: 0.35)
    static let accent = UIColor(red: 1.0, green: 0.22, blue: 0.37, alpha: 1)
    static let separator = UIColor(white: 1.0, alpha: 0.08)

    static func label(_ size: CGFloat, _ weight: UIFont.Weight = .regular, color: UIColor = text) -> UILabel {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.backgroundColor = .clear
        return l
    }

    static func button(_ title: String, size: CGFloat, weight: UIFont.Weight = .medium, color: UIColor = text) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(color, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: size, weight: weight)
        return b
    }

    /// Text-rendered glyph icon (no SF Symbols needed — works on iOS 12).
    static func glyphImage(_ text: String, size: CGFloat, color: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.8, weight: .semibold),
                .foregroundColor: color
            ]
            let s = NSAttributedString(string: text, attributes: attrs)
            let b = s.boundingRect(
                with: CGSize(width: size, height: size),
                options: [.usesLineFragmentOrigin],
                context: nil
            )
            s.draw(at: CGPoint(x: (size - b.width) / 2, y: (size - b.height) / 2))
        }
    }

    static func solid(_ color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: CGPoint.zero, size: size))
        }
    }

    static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let t = Int(seconds)
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

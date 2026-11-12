import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.beginReceivingRemoteControlEvents()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = Theme.bg

        let music = UINavigationController(rootViewController: HomeViewController())
        let downloads = UINavigationController(rootViewController: DownloadsViewController())
        let settings = UINavigationController(rootViewController: SettingsViewController())

        let navs = [music, downloads, settings]
        let titles = ["Music", "Downloads", "Settings"]
        let glyphs = ["▶", "⬇", "⚙"]
        let tabs = UITabBarController()
        for i in 0..<navs.count {
            navs[i].tabBarItem = UITabBarItem(title: titles[i], image: Theme.glyphImage(glyphs[i], size: 22), tag: i)
        }
        tabs.viewControllers = navs

        let bar = tabs.tabBar
        bar.barTintColor = Theme.card
        bar.tintColor = Theme.accent
        bar.unselectedItemTintColor = Theme.textFaint
        bar.isTranslucent = true

        window.rootViewController = tabs

        let mini = MiniPlayerBar(frame: CGRect.zero)
        mini.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(mini)
        NSLayoutConstraint.activate([
            mini.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            mini.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            mini.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: 49),
            mini.heightAnchor.constraint(equalToConstant: 58)
        ])
        mini.observePlayer()

        window.makeKeyAndVisible()
        self.window = window

        styleNavigationBars()
        return true
    }

    private func styleNavigationBars() {
        let appearance = UINavigationBar.appearance()
        appearance.barStyle = .black
        appearance.tintColor = Theme.accent
        appearance.titleTextAttributes = [
            .foregroundColor: Theme.text,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
    }
}

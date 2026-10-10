import SwiftUI
import UIKit

@main
struct AllezApp: App {
    @State private var appState = AppState()

    init() {
        Self.styleBars()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .fontDesign(.rounded)
                .tint(Theme.accent)
                .preferredColorScheme(.light)
        }
    }

    /// Cream title bars with rounded, heavy titles, and a white tab bar.
    private static func styleBars() {
        func rounded(_ style: UIFont.TextStyle, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)
            return UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: 0)
        }
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.background)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [.font: rounded(.largeTitle, .heavy)]
        nav.titleTextAttributes = [.font: rounded(.headline, .heavy)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = .white
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

//
//  AppCoordinator.swift
//  LevelAssignment
//

import SwiftUI
import UIKit

final class AppCoordinator {
    private let navigationController: UINavigationController

    init(window: UIWindow) {
        navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
    }

    func start() {
        let libraryView = LibraryView { [weak self] session in
            self?.showPlayer(for: session)
        }
        let hostingController = UIHostingController(rootView: libraryView)
        hostingController.title = "MiniCalm"
        navigationController.setViewControllers([hostingController], animated: false)
    }

    private func showPlayer(for session: Session) {
        let playerViewController = PlayerViewController(session: session)
        navigationController.pushViewController(playerViewController, animated: true)
    }
}

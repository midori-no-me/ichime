//
//  SceneController.swift
//  Ichime
//
//  Created by Nikita Nafranets on 22.03.2024.
//

import Foundation
import SwiftUI

struct SceneController {
    private var scene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }

    private var rootViewController: UIViewController? {
        scene?.windows.first?.rootViewController
    }

    func isPresent(_ view: UIViewController) -> Bool {
        view === rootViewController?.presentedViewController
    }

    func present(_ view: UIViewController, _ onPresent: @escaping () -> Void) {
        // Get the key window scene
        if let rootViewController {
            // Present the AVPlayerViewController modally
            rootViewController.present(view, animated: true) {
                onPresent()
            }
        }
    }
}

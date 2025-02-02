import Foundation
import SwiftUI

struct SceneController {
  private var scene: UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
  }

  private var rootViewController: UIViewController? {
    self.scene?.windows.first?.rootViewController
  }

  func isBusy() -> Bool {
    self.rootViewController?.presentedViewController != nil
  }

  func isPresent(_ view: UIViewController) -> Bool {
    view === self.rootViewController?.presentedViewController
  }

  func present(_ view: UIViewController, _ onPresent: @escaping () -> Void) {
    if view.presentingViewController != nil {
      onPresent()
      return
    }

    DispatchQueue.main.async {
      // Get the key window scene
      if let rootViewController {
        if self.isBusy() {
          print("is busy")
          rootViewController.dismiss(animated: false) {
            print("dismiss old view and present new")
            // Present the AVPlayerViewController modally
            rootViewController.present(view, animated: true) {
              print("success present new after dismiss")
              onPresent()
            }
          }
        }
        else {
          print("present view")
          // Present the AVPlayerViewController modally
          rootViewController.present(view, animated: true) {
            print("present view success")
            onPresent()
          }
        }
      }
    }
  }
}

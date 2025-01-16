import AVKit
import Foundation
import SwiftUI

final class VideoPlayerController: NSObject {
  private let logger = createLogger(category: String(describing: VideoPlayerController.self))

  private let playerViewController = AVPlayerViewController()
  private var coordinator: Coordinator?
  private let sceneController = SceneController()

  private(set) var player: AVPlayer?

  private var playerItem: AVPlayerItem?
  private var playerItemObserver: NSKeyValueObservation?
  private var loadingIndicator: UIActivityIndicatorView?

  private(set) var isInPiP = false

  override init() {
    super.init()
    logger.debug("create player")

    coordinator = Coordinator(self)
    playerViewController.allowsPictureInPicturePlayback = true
    playerViewController.delegate = coordinator
  }

  func showPlayer(player: AVPlayer) {
    self.player?.pause()
    logger.debug("show player")
    playerViewController.player = player
    self.player = player
    self.playerItem = player.currentItem

    // Start observing the playerItem's buffering status
    startObservingBuffering()
    sceneController.present(playerViewController) {
      player.play()
      self.addLoadingIndicator()
    }
  }

  private func startObservingBuffering() {
    playerItemObserver = playerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) {
      [weak self] playerItem, change in
      guard let self = self else { return }

      if let isPlaybackLikelyToKeepUp = change.newValue {
        if isPlaybackLikelyToKeepUp {
          // Hide the loading indicator
          self.hideLoadingIndicator()
        }
        else {
          // Show the loading indicator
          self.showLoadingIndicator()
        }
      }

      if playerItem.isPlaybackBufferEmpty {
        // Handle buffer empty situation
        // For example, you could pause the player and show a buffering indicator
        self.player?.pause()
      }
    }
  }

  private func addLoadingIndicator() {
    if self.loadingIndicator != nil {
      return
    }

    let loadingIndicator = UIActivityIndicatorView(style: .large)
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    loadingIndicator.hidesWhenStopped = true
    playerViewController.view.addSubview(loadingIndicator)

    // Center the indicator in the playerViewController's view
    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: playerViewController.view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: playerViewController.view.centerYAnchor),
    ])

    self.loadingIndicator = loadingIndicator
  }

  private func showLoadingIndicator() {
    loadingIndicator?.startAnimating()
  }

  private func hideLoadingIndicator() {
    loadingIndicator?.stopAnimating()
  }

  func play(player: AVPlayer) {
    self.player?.pause()
    logger.debug("play player")
    playerViewController.player = player
    self.player = player
    player.play()
  }

  func dispose() {
    pausePlayer()
    playerViewController.player = nil
    player = nil
    sceneController.dismiss()
  }

  func pausePlayer() {
    logger.info("pause player")
    player?.pause()
  }
}

extension VideoPlayerController {
  static func enableBackgroundMode() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .moviePlayback)
    }
    catch {
      print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
  }

  class Coordinator: NSObject, AVPlayerViewControllerDelegate {
    var control: VideoPlayerController

    init(_ control: VideoPlayerController) {
      self.control = control
    }

    func playerViewControllerDidStartPictureInPicture(_: AVPlayerViewController) {
      control.isInPiP = true
    }

    func playerViewControllerDidStopPictureInPicture(_: AVPlayerViewController) {
      control.isInPiP = false
    }

    // Не ломает пип после выхода из пипа
    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping
      (
        Bool
      )
        -> Void
    ) {
      if control.sceneController.isPresent(playerViewController) {
        return
      }

      control.sceneController.present(playerViewController) {
        completionHandler(false)
      }
    }
  }
}

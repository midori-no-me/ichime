import AVKit
import Foundation
import SwiftUI

final class VideoPlayerController: NSObject {
  private let logger = createLogger(category: String(describing: VideoPlayerController.self))

  private let playerViewController: AVPlayerViewController = .init()
  private var coordinator: Coordinator?
  private let sceneController: SceneController = .init()

  private(set) var player: AVPlayer?

  private var playerItem: AVPlayerItem?
  private var playerItemObserver: NSKeyValueObservation?
  private var loadingIndicator: UIActivityIndicatorView?

  private(set) var isInPiP = false

  override init() {
    super.init()
    self.logger.debug("create player")

    self.coordinator = Coordinator(self)
    self.playerViewController.allowsPictureInPicturePlayback = true
    self.playerViewController.delegate = self.coordinator
  }

  func showPlayer(player: AVPlayer) {
    self.player?.pause()
    self.logger.debug("show player")
    self.playerViewController.player = player
    self.player = player
    self.playerItem = player.currentItem

    // Start observing the playerItem's buffering status
    self.startObservingBuffering()
    self.sceneController.present(self.playerViewController) {
      player.play()
      self.addLoadingIndicator()
    }
  }

  private func startObservingBuffering() {
    self.playerItemObserver = self.playerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) {
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
    self.playerViewController.view.addSubview(loadingIndicator)

    // Center the indicator in the playerViewController's view
    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: self.playerViewController.view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: self.playerViewController.view.centerYAnchor),
    ])

    self.loadingIndicator = loadingIndicator
  }

  private func showLoadingIndicator() {
    self.loadingIndicator?.startAnimating()
  }

  private func hideLoadingIndicator() {
    self.loadingIndicator?.stopAnimating()
  }

  func play(player: AVPlayer) {
    self.player?.pause()
    self.logger.debug("play player")
    self.playerViewController.player = player
    self.player = player
    player.play()
  }

  func dispose() {
    self.pausePlayer()
    self.playerViewController.player = nil
    self.player = nil
    self.sceneController.dismiss()
  }

  func pausePlayer() {
    self.logger.info("pause player")
    self.player?.pause()
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
      self.control.isInPiP = true
    }

    func playerViewControllerDidStopPictureInPicture(_: AVPlayerViewController) {
      self.control.isInPiP = false
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
      if self.control.sceneController.isPresent(playerViewController) {
        return
      }

      self.control.sceneController.present(playerViewController) {
        completionHandler(false)
      }
    }
  }
}

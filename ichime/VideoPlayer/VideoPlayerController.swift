//
//  Player.swift
//  ichime
//
//  Created by Nikita Nafranets on 21.01.2024.
//

import AVKit
import Foundation
import SwiftUI

final class VideoPlayerController: NSObject {
    private let logger = createLogger(category: String(describing: VideoPlayerController.self))

    private let playerViewController = AVPlayerViewController()
    private var coordinator: Coordinator?
    private let sceneController = SceneController()

    private(set) var player: AVPlayer?

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
        sceneController.present(playerViewController) {
            player.play()
        }
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
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var control: VideoPlayerController

        init(_ control: VideoPlayerController) {
            self.control = control
        }

        #if !os(tvOS)
            func playerViewController(
                _: AVPlayerViewController,
                willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator
            ) {
                // Called when the player enters fullscreen mode
            }

            func playerViewController(
                _: AVPlayerViewController,
                willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator
            ) {
                // Called when the player exits fullscreen mode
                control.pausePlayer()
            }
        #endif

        func playerViewControllerDidStartPictureInPicture(_: AVPlayerViewController) {
            control.isInPiP = true
        }

        func playerViewControllerDidStopPictureInPicture(_: AVPlayerViewController) {
            control.isInPiP = false
        }

        // Не ломает пип после выхода из пипа
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (
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

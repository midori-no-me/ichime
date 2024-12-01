//
//  VideoPlayerHolder.swift
//  Ichime
//
//  Created by Nikita Nafranets on 10.04.2024.
//

import Foundation

class VideoPlayerHolder {
  private var videoPlayerController: VideoPlayerController = .init()
  private var player: VideoPlayer = .init()
  private var isBusy = false
  private var hasSubsLastTime: Bool = false

  @MainActor
  private func pause() {
    videoPlayerController.pausePlayer()
  }

  @MainActor
  private func recreate() {
    videoPlayerController.dispose()
    videoPlayerController = .init()
  }

  func play(video: VideoModel, onDismiss dismiss: @escaping () -> Void = {}) async {
    if isBusy {
      return
    }

    isBusy = true

    if videoPlayerController.player != nil {
      await pause()
    }

    #if os(iOS)

      //            if hasSubsLastTime, videoPlayerController.player != nil {
      //                await recreate()
      //            }
      //
      //            hasSubsLastTime = video.subtitleURL != nil

    #endif

    player = VideoPlayer()

    if let translationId = video.translationId {
      player.addObserver(WatchChecker(translationId: translationId))
    }

    await player.createPlayer(
      video: video
    )

    guard let avplayer = player.player else {
      return
    }

    await MainActor.run {
      if videoPlayerController.isInPiP {
        dismiss()
        videoPlayerController.play(player: avplayer)
        isBusy = false

        return
      }

      videoPlayerController.showPlayer(player: avplayer)
      isBusy = false
    }
  }
}

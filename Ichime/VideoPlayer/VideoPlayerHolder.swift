import Foundation

class VideoPlayerHolder {
  private var videoPlayerController: VideoPlayerController = .init()
  private var player: VideoPlayer = .init()
  private var isBusy = false
  private var hasSubsLastTime: Bool = false

  @MainActor
  private func pause() {
    self.videoPlayerController.pausePlayer()
  }

  @MainActor
  private func recreate() {
    self.videoPlayerController.dispose()
    self.videoPlayerController = .init()
  }

  func play(video: VideoModel, onDismiss dismiss: @escaping () -> Void = {}) async {
    if self.isBusy {
      return
    }

    self.isBusy = true

    if self.videoPlayerController.player != nil {
      await self.pause()
    }

    self.player = VideoPlayer()

    if let translationId = video.translationId {
      self.player.addObserver(WatchChecker(translationId: translationId))
    }

    await self.player.createPlayer(
      video: video
    )

    guard let avplayer = player.player else {
      return
    }

    await MainActor.run {
      if self.videoPlayerController.isInPiP {
        dismiss()
        self.videoPlayerController.play(player: avplayer)
        self.isBusy = false

        return
      }

      self.videoPlayerController.showPlayer(player: avplayer)
      self.isBusy = false
    }
  }
}

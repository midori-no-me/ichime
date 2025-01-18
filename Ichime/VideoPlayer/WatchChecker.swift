import AVFoundation
import Foundation
import ScraperAPI

actor WatchChecker: VideoPlayerObserver {
  let translationId: Int
  let api: ScraperAPI.APIClient

  let logger = createLogger(category: String(describing: WatchChecker.self))

  var videoDuration: CMTime = .zero
  weak var player: AVPlayer?
  var timeObserverToken: Any?

  var isStarted = false

  init(translationId: Int) {
    self.translationId = translationId
    self.api = ApplicationDependency.container.resolve()
  }

  func savePlayer(_ player: AVPlayer) {
    self.player = player
  }

  nonisolated func create(player: AVPlayer) {
    self.logger.notice("add watcher to player")
    Task {
      if await self.player != nil {
        print("already setted watcher")
        return
      }
      await self.savePlayer(player)
      await self.saveDuration(player)
      await self.addObserver(player)
    }
  }

  nonisolated func destroy() {
    Task {
      await self.removeObserver()
    }
  }

  // Set up an observer to track changes in the current time
  func addObserver(_ player: AVPlayer) {
    var times: [NSValue] = []
    // Set initial time to zero
    var currentTime = CMTimeMultiplyByFloat64(videoDuration, multiplier: 0.85)
    // Divide the asset's duration into quarters.
    let interval = CMTimeMultiplyByFloat64(videoDuration, multiplier: 0.001)

    // Build boundary times at 25%, 50%, 75%, 100%
    while currentTime < self.videoDuration {
      currentTime = currentTime + interval
      times.append(NSValue(time: currentTime))
    }

    self.logger.notice("add observer")
    self.timeObserverToken = player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
      [weak self] in
      guard let self = self else {
        return
      }
      Task {
        await self.performUpdateWatch()
      }
    }
  }

  func removeObserver() {
    self.logger.notice("remove watcher observer")
    if let timeObserverToken, let player {
      player.removeTimeObserver(timeObserverToken)
      self.timeObserverToken = nil
    }
  }

  func saveDuration(_ player: AVPlayer) async {
    guard let asset = player.currentItem?.asset else { return }
    do {
      self.videoDuration = try await asset.load(.duration)
    }
    catch {
      self.logger.error("Cannot get duration \(error)")
    }
  }

  func performUpdateWatch() async {
    if self.isStarted {
      return
    }
    self.isStarted = true
    let id = self.translationId
    do {
      self.logger.notice("Update watch translationId: \(id)")
      try await self.api.sendAPIRequest(
        ScraperAPI.Request
          .UpdateCurrentWatch(translationId: self.translationId)
      )
      self.removeObserver()
    }
    catch {
      self.logger.error("Cannot update watch \(error)")
    }
  }
}

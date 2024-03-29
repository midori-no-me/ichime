//
//  WatchChecker.swift
//  Ichime
//
//  Created by Nikita Nafranets on 22.03.2024.
//

import AVFoundation
import Foundation
import ScraperAPI

actor WatchChecker: VideoPlayerDelegate {
    let translationId: Int
    let api: ScraperAPI.APIClient
    var videoDuration: CMTime = .zero
    var player: AVPlayer = .init()
    var timeObserverToken: Any?

    init(translationId: Int) {
        self.translationId = translationId
        api = ApplicationDependency.container.resolve()
    }

    func savePlayer(_ player: AVPlayer) {
        self.player = player
    }

    nonisolated func show(player: AVPlayer) {
        print("show player")
        Task {
            await savePlayer(player)
            await saveDuration(player)
            await addObserver(player)
        }
    }

    nonisolated func destroy() {
        Task {
            await removeObserver()
        }
    }

    // Set up an observer to track changes in the current time
    func addObserver(_ player: AVPlayer) {
        var times = [NSValue]()
        // Set initial time to zero
        var currentTime = CMTimeMultiplyByFloat64(videoDuration, multiplier: 0.85)
        // Divide the asset's duration into quarters.
        let interval = CMTimeMultiplyByFloat64(videoDuration, multiplier: 0.001)

        // Build boundary times at 25%, 50%, 75%, 100%
        while currentTime < videoDuration {
            currentTime = currentTime + interval
            times.append(NSValue(time: currentTime))
        }

        print("add observer")
        timeObserverToken = player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            print(player.currentTime().seconds)
            guard let self = self else { return }
            Task {
                await self.performUpdateWatch()
                await self.removeObserver()
            }
        }
    }

    func removeObserver() {
        print("remove observer")
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    func saveDuration(_ player: AVPlayer) async {
        guard let asset = player.currentItem?.asset else { return }
        do {
            videoDuration = try await asset.load(.duration)
        } catch {
            print("cannot get duration \(error)")
        }
    }

    func performUpdateWatch() async {
        do {
            print("update watch")
            try await api.sendAPIRequest(
                ScraperAPI.Request
                    .UpdateCurrentWatch(translationId: translationId)
            )
        } catch {
            print("Cannot update watch \(error)")
        }
    }
}

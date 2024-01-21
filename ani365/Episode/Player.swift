//
//  Player.swift
//  ani365
//
//  Created by Nikita Nafranets on 21.01.2024.
//

import AVKit
import Foundation
import SwiftUI

struct PlayerView: UIViewControllerRepresentable {
    let showFullScreen: Bool
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
        chooseScreenType(playerViewController)

        return playerViewController
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context content: Context) {
        chooseScreenType(controller)
    }

    private func chooseScreenType(_ controller: AVPlayerViewController) {
        if showFullScreen {
            controller.enterFullScreen(animated: true)
        } else {
            controller.exitFullScreen(animated: true)
        }
    }
}


extension AVPlayerViewController {
    func enterFullScreen(animated: Bool) {
        print("Enter full screen")
        perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }

    func exitFullScreen(animated: Bool) {
        print("Exit full screen")
        perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: animated, with: nil)
    }
}

// struct Player: View {
//    let videoURL: URL
//    let subtitleURL: URL?
//
//    @StateObject var manager: VideoPlayerController = .init()
//
//    var body: some View {
//        VStack {
//            GeometryReader { proxy in
//                ZStack {
//                    if let player = manager.player {
//                        PlayerView(showFullScreen: manager.isPlay, player: player)
//                            .offset(x: 0, y: proxy.size.height - 1)
//                    }
//                }
//            }.ignoresSafeArea()
//
//        }
////        .task {
////            if manager.player == nil, manager.loading == false {
////                await manager.createPlayer(videoURL, subtitleURL)
////            }
////        }
//    }
// }

class VideoPlayerController: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlay = false
    @Published var loading = false

    func play() {
        print("play")
        isPlay = true
        player?.play()
    }

    func stop() {
        print("stop")
        player?.pause()
        player = nil
        isPlay = false
    }

    private func downloadSubtitles(from url: URL) async throws -> URL {
        let fileName = "\(url.absoluteString.components(separatedBy: "/").last ?? UUID().uuidString).vtt"

        print(fileName)
        let (tempLocalUrl, _) = try await URLSession.shared.download(from: url)

        let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let destinationUrl = documentsDirectory.appendingPathComponent(fileName)

        // Remove the file if it already exists
        try? FileManager.default.removeItem(at: destinationUrl)

        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl)

        return destinationUrl
    }

    func createPlayer(_ videoURL: URL, _ subtitleURL: URL?) async {
        if loading {
            return
        }

        DispatchQueue.main.async {
            self.loading = true
        }

        let videoAsset = AVAsset(url: videoURL)

        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        do {
            try videoTrack?.insertTimeRange(
                CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                of: videoAsset.tracks(withMediaType: .video)[0],
                at: .zero
            )
            try audioTrack?.insertTimeRange(
                CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                of: videoAsset.tracks(withMediaType: .audio)[0],
                at: .zero
            )
        } catch {
            print("Error inserting tracks: \(error)")
            return
        }

        if let subtitleURL, let subtitleFile = try? await downloadSubtitles(from: subtitleURL) {
            let subtitleAsset = AVAsset(url: subtitleFile)
            let subtitleTrack = composition.addMutableTrack(
                withMediaType: .text,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )

            do {
                try subtitleTrack?.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: subtitleAsset.duration),
                    of: subtitleAsset.tracks(withMediaType: .text)[0],
                    at: .zero
                )
            } catch {
                print("Error inserting subtitle track: \(error)")
                return
            }
        }

        let playerItem = AVPlayerItem(asset: composition)

        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = NSString(string: "Episode 8")

        let subtitleItem = AVMutableMetadataItem()
        subtitleItem.identifier = .iTunesMetadataTrackSubTitle
        subtitleItem.value = NSString(string: "Isekai Nonbiri Nouka")

        playerItem.externalMetadata = [
            titleItem,
            subtitleItem
        ]

        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true

        await MainActor.run {
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
            self.player = player
            self.loading = false
        }
        await MainActor.run {
            self.play()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === player {
            if keyPath == "timeControlStatus", player?.timeControlStatus == .paused {
                player?.pause()
                isPlay = false
                player?.removeObserver(self, forKeyPath: "timeControlStatus")
            }
        }
    }
}

// #Preview {
//    Player(videoURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4")!, subtitleURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.vtt")!)
// }

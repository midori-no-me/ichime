//
//  Player.swift
//  ani365
//
//  Created by Nikita Nafranets on 21.01.2024.
//

import AVKit
import Foundation
import SwiftUI

struct VideoPlayerExample: View {
    let video: VideoModel

    @StateObject var manager: VideoPlayerController = .init()

    var body: some View {
        Button("Play video") {
            Task {
                await manager.play(video: video)
            }
        }
    }
}

struct VideoModel {
    let videoURL: URL
    let subtitleURL: URL?

    let title: String?
    let episodeTitle: String?
}

class VideoPlayerController: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var loading = false

    var coordinator: Coordinator?

    private func createPlayer() {
        print("create player")
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        coordinator = Coordinator(self)
        playerViewController.delegate = coordinator

        // Get the key window scene
        if let keyWindowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        {
            // Present the AVPlayerViewController modally
            keyWindowScene.windows.first?.rootViewController?.present(playerViewController, animated: true) {
                playerViewController.player?.play()
                // do we need to change orientation ?
//                self.changeOrientation(to: .all)
            }
        }
    }

    private func destroyPlayer() {
        print("stop")
        player?.pause()
        player = nil
        loading = false
//        changeOrientation(to: .portrait)
    }

    private func downloadSubtitles(from url: URL) async throws -> URL {
        let fileName = "\(url.absoluteString.components(separatedBy: "/").last ?? UUID().uuidString).vtt"

        let (tempLocalUrl, _) = try await URLSession.shared.download(from: url)

        let documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let destinationUrl = documentsDirectory.appendingPathComponent(fileName)

        // Remove the file if it already exists
        try? FileManager.default.removeItem(at: destinationUrl)

        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl)

        return destinationUrl
    }

    func play(video: VideoModel) async {
        if loading {
            return
        }

        DispatchQueue.main.async {
            self.loading = true
        }

        let videoURL = video.videoURL
        let subtitleURL = video.subtitleURL

        let videoAsset = AVAsset(url: videoURL)
        var subtitleAsset: AVAsset? = nil

        if let subtitleURL, let subtitleFile = try? await downloadSubtitles(from: subtitleURL) {
            subtitleAsset = AVAsset(url: subtitleFile)
        }

        let composition = AVMutableComposition()

        let mediaTypes: [AVMediaType: AVAsset?] = [.video: videoAsset, .audio: videoAsset, .text: subtitleAsset]

        for (mediaType, avAsset) in mediaTypes {
            guard let avAsset else {
                continue
            }

            do {
                let track = composition.addMutableTrack(
                    withMediaType: mediaType,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )!
                let assetTrack = try await avAsset.loadTracks(withMediaType: mediaType).first!
                let trackTimeRange = try await assetTrack.load(.timeRange)
                try track.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: trackTimeRange.duration),
                    of: assetTrack,
                    at: .zero
                )
            } catch {
                print("Error inserting \(mediaType.rawValue) track: \(error)")
                return
            }
        }

        let playerItem = AVPlayerItem(asset: composition)

        let metadata = prepareMetadata(video: video)
        if !metadata.isEmpty {
            playerItem.externalMetadata = metadata
        }

        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true

        await MainActor.run {
            self.player = player
            self.loading = false
            self.createPlayer()
        }
    }

    private func prepareMetadata(video: VideoModel) -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = []
        if let episodeTitle = video.episodeTitle {
            let episodeTitleItem = AVMutableMetadataItem()
            episodeTitleItem.identifier = .commonIdentifierTitle
            episodeTitleItem.value = NSString(string: episodeTitle)
            metadata.append(episodeTitleItem)
        }

        if let title = video.title {
            let showTitleItem = AVMutableMetadataItem()
            showTitleItem.identifier = .iTunesMetadataTrackSubTitle
            showTitleItem.value = NSString(string: title)
            metadata.append(showTitleItem)
        }

        return metadata
    }

    private func changeOrientation(to orientation: UIInterfaceOrientationMask) {
        // tell the app to change the orientation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        print("Changing to", orientation == .portrait ? "portrait" : "landscape")
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var control: VideoPlayerController

        init(_ control: VideoPlayerController) {
            self.control = control
        }

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
            control.destroyPlayer()
        }
    }
}

struct VideoPlayerLoader: View {
    var body: some View {
        Color(UIColor.systemBackground).ignoresSafeArea(.all).overlay {
            ProgressView("Загружаем видео")
        }
    }
}

#Preview {
    VideoPlayerExample(video: .init(
        videoURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4")!,
        subtitleURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.vtt")!,
        title: "Arknights",
        episodeTitle: "Episode 1"
    ))
}

#Preview("Loader") {
    ZStack {
        VideoPlayerLoader()
    }
}

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
                await manager.play(video: video, onDoneWatch: {})
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

final class VideoPlayerController: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var loading = false

    var timeObserverToken: Any?
    var onDoneWatch: (() -> Void)?

    var coordinator: Coordinator?
    var videoDuration: Double = 0.0

    static func enableBackgroundMode() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    private var scene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }

    private func present(_ controller: AVPlayerViewController, _ onPresent: @escaping () -> Void) {
        // Get the key window scene
        if let keyWindowScene = scene {
            // Present the AVPlayerViewController modally
            keyWindowScene.windows.first?.rootViewController?.present(controller, animated: true) {
                onPresent()
            }
        }
    }

    private func createPlayer() {
        print("create player")
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.allowsPictureInPicturePlayback = true
        coordinator = Coordinator(self)
        playerViewController.delegate = coordinator

        present(playerViewController) {
            self.player?.play()
        }
    }

    private func destroyPlayer() {
        print("stop")
        if let player {
            player.pause()
            if let timeObserverToken {
                player.removeTimeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }
        }

        player = nil
        loading = false
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

    func play(video: VideoModel, onDoneWatch: @escaping () -> Void) async {
        if loading {
            return
        }

        self.onDoneWatch = onDoneWatch

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
                if mediaType == .video {
                    videoDuration = trackTimeRange.duration.seconds
                }
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

        // Set up an observer to track changes in the current time
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1, timescale: 1),
            queue: .main
        ) { time in
            if time.seconds / self.videoDuration >= 0.9 {
                if let timeObserverToken = self.timeObserverToken,
                   let player = self.player,
                   let onDoneWatch = self.onDoneWatch
                {
                    print("done watching")
                    onDoneWatch()
                    player.removeTimeObserver(timeObserverToken)
                    self.timeObserverToken = nil
                }
            }
        }

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

        // Не ломает пип после выхода из пипа
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (
                Bool
            )
                -> Void
        ) {
            if playerViewController === control.scene?.windows.first?.rootViewController?.presentedViewController {
                return
            }

            control.present(playerViewController) {
                completionHandler(false)
            }
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

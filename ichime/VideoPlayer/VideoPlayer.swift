//
//  Player.swift
//  ichime
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
                await manager.createPlayer(video: video)
                manager.showPlayer()
            }
        }
    }
}

protocol VideoPlayerDelegate {
    func show(player: AVPlayer) -> Void
    func destroy() -> Void
}

final class VideoPlayerController: NSObject, ObservableObject {
    var player: AVPlayer?

    private var coordinator: Coordinator?
    private let sceneController = SceneController()
    private var delegate: VideoPlayerDelegate?

    private let logger = createLogger(category: String(describing: VideoPlayerController.self))

    static func enableBackgroundMode() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    func addDelegate(_ delegate: VideoPlayerDelegate) {
        self.delegate = delegate
    }

    func showPlayer() {
        logger.debug("create player")
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.allowsPictureInPicturePlayback = true
        coordinator = Coordinator(self)
        playerViewController.delegate = coordinator

        if let player, let delegate {
            delegate.show(player: player)
        }

        sceneController.present(playerViewController) {
            self.player?.play()
        }
    }

    private func destroyPlayer() {
        logger.info("destroy player")
        player?.pause()
        delegate?.destroy()

        delegate = nil
        player = nil
    }

    func downloadFileToTemporaryDirectory(from url: URL) async throws -> URL {
        let session = URLSession(configuration: .default)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "HTTP Error", code: statusCode, userInfo: nil)
        }

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let filename = "\(url.lastPathComponent).vtt"
        let destinationURL = temporaryDirectoryURL.appendingPathComponent(filename)

        // Remove the file if it already exists
        try? FileManager.default.removeItem(at: destinationURL)

        try data.write(to: destinationURL)

        print("file downloaded \(destinationURL)")
        return destinationURL
    }

    func createSubtitleAsset(from url: URL?) async -> AVAsset? {
        guard let url, let filepath = try? await downloadFileToTemporaryDirectory(from: url) else {
            return nil
        }
        return AVAsset(url: filepath)
    }

    enum PlayerError: Error {
        case compositionError(String)
    }

    func createMutableComposition(
        _ videoAsset: AVAsset,
        _ subtitleAsset: AVAsset
    ) async throws -> AVMutableComposition {
        let composition = AVMutableComposition()

        let mediaTypes: [AVMediaType: AVAsset] = [.video: videoAsset, .audio: videoAsset, .text: subtitleAsset]

        for (mediaType, avAsset) in mediaTypes {
            do {
                let assetTrack = try await avAsset.loadTracks(withMediaType: mediaType).first!

                let trackTimeRange = try await assetTrack.load(.timeRange)

                let track = composition.addMutableTrack(
                    withMediaType: mediaType,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )!

                try track.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: trackTimeRange.duration),
                    of: assetTrack,
                    at: .zero
                )
            } catch {
                throw PlayerError.compositionError("Error inserting \(mediaType.rawValue) track: \(error)")
            }
        }

        return composition
    }

    func createPlayer(video: VideoModel) async {
        let videoURL = video.videoURL
        let subtitleURL = video.subtitleURL

        let videoAsset = AVAsset(url: videoURL)
        let subtitleAsset = await createSubtitleAsset(from: subtitleURL)

        let playerItem: AVPlayerItem

        if let subtitleAsset,
           let composition = try? await createMutableComposition(videoAsset, subtitleAsset)
        {
            playerItem = .init(asset: composition)
        } else {
            playerItem = .init(asset: videoAsset)
        }

        let metadata = MetadataCollector.createMetadata(
            title: video.title,
            subtitle: video.subtitle,
            description: video.description
        )

        if !metadata.isEmpty {
            playerItem.externalMetadata = metadata
        }

        // Буферим 10 секунд видео
        playerItem.preferredForwardBufferDuration = 10

        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = subtitleURL == nil
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        player.preventsDisplaySleepDuringVideoPlayback = true

        // TODO: Проверить что на tvOS что оно не в тру по умолчанию
        print("automaticallyWaitsToMinimizeStalling \(player.automaticallyWaitsToMinimizeStalling)")

        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
    }

    #if !os(tvOS)
        private func changeOrientation(to orientation: UIInterfaceOrientationMask) {
            // tell the app to change the orientation
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            print("Changing to", orientation == .portrait ? "portrait" : "landscape")
        }
    #endif

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
                control.destroyPlayer()
            }
        #endif

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

struct VideoPlayerLoader: View {
    var body: some View {
        #if !os(tvOS)
            Color(UIColor.systemBackground).ignoresSafeArea(.all).overlay {
                ProgressView("Загружаем видео")
            }
        #endif
    }
}

#Preview {
    VideoPlayerExample(video: .init(
        videoURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4")!,
        subtitleURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.vtt")!,
        title: "Episode 1",
        subtitle: "Arknights",
        description: nil
    ))
}

#Preview("Loader") {
    ZStack {
        VideoPlayerLoader()
    }
}

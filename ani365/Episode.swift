import AVKit
import Foundation
import UIKit

class Episode: UIViewController {
    let videoUrl = "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4"
    let subtitleUrl = "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.vtt"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playVideo()
    }

    private func playVideo() {
        let videoAsset = AVAsset(url: URL(string: videoUrl)!)
        let subtitleAsset = AVAsset(url: URL(string: subtitleUrl)!)

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

        let playerItem = AVPlayerItem(asset: composition)
        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true

        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
}

#Preview {
    Episode()
}

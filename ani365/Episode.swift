import AVKit
import Foundation
import UIKit

class Episode: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playVideo()
    }

    private func playVideo() {
        let subtitlesConverter = SubtitlesConverter()

        subtitlesConverter.convertAssSubtitlesToVtt(
            inputSubtitlesUrl: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.ass"
        ) { (result: Result<String, SubtitlesConverterError>) in
            switch result {
            case .success(let subtitlesPath):
                DispatchQueue.main.async {
                    var videoAsset = AVAsset(url: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4")!)
                    let subtitleURL = URL(fileURLWithPath: subtitlesPath) // Replace with the actual URL of your subtitles file

                    let composition = AVMutableComposition()
                    let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                    let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

                    do {
                        try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .video)[0], at: .zero)
                        try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .audio)[0], at: .zero)
                    } catch {
                        print("Error inserting tracks: \(error)")
                        return
                    }

                    let subtitleAsset = AVURLAsset(url: subtitleURL)
                    let subtitleTrack = composition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)

                    do {
                        try subtitleTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: subtitleAsset.duration), of: subtitleAsset.tracks(withMediaType: .text)[0], at: .zero)
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
                    self.present(playerController, animated: true) {
                        player.play()
                    }
                }
            case .failure(let error):
                print("Error converting subtitles: \(error)")
            }
        }
    }
}

#Preview {
    Episode()
}

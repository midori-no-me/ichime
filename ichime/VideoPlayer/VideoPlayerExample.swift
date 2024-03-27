//
//  VideoPlayerExample.swift
//  Ichime
//
//  Created by Nikita Nafranets on 28.03.2024.
//

import SwiftUI

struct VideoPlayerExample: View {
    let video: VideoModel

    var videoView: VideoPlayerController = .init()
    var videoPlayer: VideoPlayer = .init()

    var body: some View {
        Button("Play video") {
            Task {
                await videoPlayer.createPlayer(video: video)
                videoView.player = videoPlayer.player
            }
        }
    }
}

#Preview {
    VideoPlayerExample(video: .init(
        videoURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.mp4")!,
        subtitleURL: URL(string: "https://storage.yandexcloud.net/incubator.flaks.dev/1_testvideo/arknights.vtt")!,
        metadata: .init(
            title: "Episode 1",
            subtitle: "Arknights",
            description: nil,
            genre: nil,
            image: nil,
            year: nil
        )
    ))
}

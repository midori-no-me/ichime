//
//  EmbedModel.swift
//  ani365
//
//  Created by p.flaks on 20.01.2024.
//

import Anime365ApiClient
import Foundation

struct EpisodeStreamingInfo: Hashable, Identifiable {
    init(apiResponse: Anime365TranslationEmbed) {
        var subtitles: EpisodeStreamingInfo.SubtitlesUrls? = nil

        if let vttUrlString = apiResponse.subtitlesVttUrl, let vttUrl = URL(string: vttUrlString) {
            subtitles = EpisodeStreamingInfo.SubtitlesUrls(
                vtt: vttUrl
            )
        }

        self.id = apiResponse.embedUrl
        self.streamQualityOptions = apiResponse.stream.map { streamQualityOption in
            StreamQualityOption(
                id: streamQualityOption.height,
                height: streamQualityOption.height,
                urls: streamQualityOption.urls.map { streamUrlString in
                    URL(string: streamUrlString)!
                }
            )
        }
        self.subtitles = subtitles
    }

    let id: String
    let streamQualityOptions: [StreamQualityOption]
    let subtitles: SubtitlesUrls?

    static func == (lhs: EpisodeStreamingInfo, rhs: EpisodeStreamingInfo) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    struct StreamQualityOption: Hashable, Identifiable {
        var id: Int

        let height: Int
        let urls: [URL]

        static func == (lhs: StreamQualityOption, rhs: StreamQualityOption) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct SubtitlesUrls {
        let vtt: URL
    }
}

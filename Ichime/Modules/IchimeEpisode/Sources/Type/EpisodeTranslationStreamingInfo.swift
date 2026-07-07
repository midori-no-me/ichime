import Anime365Kit
import Foundation

public struct EpisodeTranslationStreamingInfo {
  public struct EpisodeTranslationStreamingQuality: Identifiable {
    public let videoUrl: URL
    public let height: Int

    public var id: URL {
      self.videoUrl
    }

    public static func createValid(
      anime365ApiTranslationEmbedStream: Anime365Kit.TranslationEmbed.Stream
    ) -> Self? {
      guard let streamingUrl = anime365ApiTranslationEmbedStream.urls.first else {
        return nil
      }

      if anime365ApiTranslationEmbedStream.height == 0 {
        return nil
      }

      return Self(
        videoUrl: streamingUrl,
        height: anime365ApiTranslationEmbedStream.height
      )
    }
  }

  public let subtitlesUrl: URL?
  public let streamingQualities: [EpisodeTranslationStreamingQuality]

  public static func createValid(
    anime365ApiTranslationEmbed: Anime365Kit.TranslationEmbed,
    anime365ApiBaseUrl: URL
  ) -> Self? {
    var subtitlesUrl: URL? = nil

    if let subtitlesUrlString = anime365ApiTranslationEmbed.subtitlesUrl {
      guard let subtitlesUrlRelativeToBaseUrl = URL(string: subtitlesUrlString, relativeTo: anime365ApiBaseUrl) else {
        return nil
      }

      subtitlesUrl = subtitlesUrlRelativeToBaseUrl
    }

    if subtitlesUrl == nil {
      subtitlesUrl = anime365ApiTranslationEmbed.subtitlesVttUrl
    }

    var items: [EpisodeTranslationStreamingQuality] = []

    for anime365ApiTranslationEmbedStream in anime365ApiTranslationEmbed.stream {
      let episodeTranslationStreamingQuality = EpisodeTranslationStreamingQuality.createValid(
        anime365ApiTranslationEmbedStream: anime365ApiTranslationEmbedStream
      )

      guard let episodeTranslationStreamingQuality else {
        continue
      }

      items.append(episodeTranslationStreamingQuality)
    }

    return Self(
      subtitlesUrl: subtitlesUrl,
      streamingQualities: items
    )
  }
}

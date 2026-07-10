import Anime365Kit
import Foundation

public struct EpisodeTranslationStreamingInfo {
  // MARK: Nested Types

  public struct EpisodeTranslationStreamingQuality: Identifiable {
    // MARK: Properties

    public let videoURL: URL
    public let height: Int

    // MARK: Computed Properties

    public var id: URL {
      self.videoURL
    }

    // MARK: Static Functions

    public static func createValid(
      anime365ApiTranslationEmbedStream: Anime365Kit.TranslationEmbed.Stream
    ) -> Self? {
      guard let streamingURL = anime365ApiTranslationEmbedStream.urls.first else {
        return nil
      }

      if anime365ApiTranslationEmbedStream.height == 0 {
        return nil
      }

      return Self(
        videoURL: streamingURL,
        height: anime365ApiTranslationEmbedStream.height
      )
    }
  }

  // MARK: Properties

  public let subtitlesURL: URL?
  public let streamingQualities: [EpisodeTranslationStreamingQuality]

  // MARK: Static Functions

  public static func createValid(
    anime365ApiTranslationEmbed: Anime365Kit.TranslationEmbed,
    anime365ApiBaseURL: URL
  ) -> Self? {
    var subtitlesURL: URL? = nil

    if let subtitlesURLString = anime365ApiTranslationEmbed.subtitlesUrl {
      guard let subtitlesURLRelativeToBaseURL = URL(string: subtitlesURLString, relativeTo: anime365ApiBaseURL) else {
        return nil
      }

      subtitlesURL = subtitlesURLRelativeToBaseURL
    }

    if subtitlesURL == nil {
      subtitlesURL = anime365ApiTranslationEmbed.subtitlesVttUrl
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
      subtitlesURL: subtitlesURL,
      streamingQualities: items
    )
  }
}

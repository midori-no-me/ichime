//
//  ViewPlayer.swift
//  Ichime
//
//  Created by Nikita Nafranets on 28.03.2024.
//
import AVFoundation

protocol VideoPlayerObserver: AnyObject {
  func create(player: AVPlayer)
  func destroy()
}

final class VideoPlayer {
  enum PlayerError: Error {
    case compositionError(String)
  }

  private var observer: VideoPlayerObserver?

  private let logger = createLogger(category: String(describing: VideoPlayer.self))

  var player: AVPlayer? {
    didSet {
      if let observer, let player {
        observer.create(player: player)
      }
    }
  }

  func addObserver(_ observer: VideoPlayerObserver) {
    self.observer = observer
    if let player {
      observer.create(player: player)
    }
  }

  func createPlayer(video: VideoModel) async {
    let videoURL = video.videoURL
    let subtitleURL = video.subtitleURL

    let videoAsset = AVURLAsset(
      url: videoURL,
      options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
    )
    let subtitleAsset = await createSubtitleAsset(from: subtitleURL)

    let playerItem: AVPlayerItem

    if let subtitleAsset,
      let composition = try? await createMutableComposition(videoAsset, subtitleAsset)
    {
      playerItem = .init(asset: composition)
    }
    else {
      playerItem = .init(asset: videoAsset)
    }

    if let metadata = video.metadata {
      let metadata = MetadataCollector.createMetadataItems(for: metadata)

      if !metadata.isEmpty {
        playerItem.externalMetadata = metadata
      }
    }

    // Буферим 600 секунд видео
    playerItem.preferredForwardBufferDuration = 30

    let player = AVPlayer(playerItem: playerItem)
    player.allowsExternalPlayback = subtitleURL == nil
    player.usesExternalPlaybackWhileExternalScreenIsActive = true
    player.preventsDisplaySleepDuringVideoPlayback = true

    self.player = player
  }

  private func downloadFileToTemporaryDirectory(from url: URL) async throws -> URL {
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

  private func createSubtitleAsset(from url: URL?) async -> AVAsset? {
    guard let url, let filepath = try? await downloadFileToTemporaryDirectory(from: url) else {
      return nil
    }
    return AVAsset(url: filepath)
  }

  private func createMutableComposition(
    _ videoAsset: AVAsset,
    _ subtitleAsset: AVAsset
  ) async throws -> AVComposition {
    let composition = AVMutableComposition()

    let mediaTypes: [AVMediaType: AVAsset] = [
      .video: videoAsset, .audio: videoAsset, .text: subtitleAsset,
    ]

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
      }
      catch {
        self.logger.error("Error inserting \(mediaType.rawValue) track: \(error, privacy: .public)")
        throw PlayerError.compositionError("Error inserting \(mediaType.rawValue) track: \(error)")
      }
    }

    guard let immutableComposition = composition.copy() as? AVComposition else {
      self.logger.error("Could not create an immutable composition copy")
      throw PlayerError.compositionError("Could not create an immutable composition copy")
    }

    return immutableComposition
  }
}

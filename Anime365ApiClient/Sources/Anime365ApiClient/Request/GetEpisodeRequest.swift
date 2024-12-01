//
//  File.swift
//
//
//  Created by Nikita Nafranets on 25.03.2024.
//

import Foundation

public struct GetEpisodeRequest: Anime365ApiRequest {
  public typealias ResponseType = Anime365ApiEpisode

  private let episodeId: Int

  public init(
    episodeId: Int
  ) {
    self.episodeId = episodeId
  }

  public func getEndpoint() -> String {
    return "/episodes/\(episodeId)"
  }

  public func getQueryItems() -> [URLQueryItem] {
    return []
  }
}

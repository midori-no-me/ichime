public struct CalendarEntry: Decodable {
  public let next_episode: Int
  public let next_episode_at: String
  public let duration: Int?
  public let anime: AnimeV1
}

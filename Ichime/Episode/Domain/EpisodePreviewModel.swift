import Foundation

struct EpisodePreview: Hashable, Identifiable {
  let id: Int
  let type: EpisodeType
  let episodeNumber: Float?

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}

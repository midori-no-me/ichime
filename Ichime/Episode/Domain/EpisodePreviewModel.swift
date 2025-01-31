import Foundation

struct EpisodePreview: Hashable, Identifiable {
  let id: Int
  let title: String?
  let typeAndNumber: String
  let uploadDate: Date?
  let type: EpisodeType
  let episodeNumber: Float?
  let isUnderProcessing: Bool

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}

enum EpisodePreviewSampleData {
  static let data = [
    EpisodePreview(
      id: 291394,
      title: "Трейлер",
      typeAndNumber: "1 серия",
      uploadDate: Date(),
      type: .trailer,
      episodeNumber: 1,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 291395,
      title: "The Journey`s End",
      typeAndNumber: "1 серия",
      uploadDate: Date(),
      type: .tv,
      episodeNumber: 1,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 312552,
      title: nil,
      typeAndNumber: "2 серия",
      uploadDate: Date(),
      type: .tv,
      episodeNumber: 2,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 312553,
      title: nil,
      typeAndNumber: "3 серия",
      uploadDate: Calendar.current.date(byAdding: .second, value: -5, to: Date())!,
      type: .tv,
      episodeNumber: 3,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 312554,
      title: nil,
      typeAndNumber: "4 серия",
      uploadDate: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!,
      type: .tv,
      episodeNumber: 4,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 312555,
      title: nil,
      typeAndNumber: "5 серия",
      uploadDate: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
      type: .tv,
      episodeNumber: 5,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 313150,
      title: nil,
      typeAndNumber: "6 серия",
      uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
      type: .tv,
      episodeNumber: 6,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 313628,
      title: nil,
      typeAndNumber: "7.5 серия",
      uploadDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
      type: .tv,
      episodeNumber: 7.5,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 314104,
      title: nil,
      typeAndNumber: "1100 серия",
      uploadDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
      type: .tv,
      episodeNumber: 1100,
      isUnderProcessing: false
    ),
    EpisodePreview(
      id: 314105,
      title: nil,
      typeAndNumber: "1101 серия",
      uploadDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
      type: .tv,
      episodeNumber: 1101,
      isUnderProcessing: true
    ),
  ]
}

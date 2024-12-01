import Foundation

struct EpisodePreview: Hashable, Identifiable {
  let id: Int
  let title: String?
  let typeAndNumber: String
  let uploadDate: Date?
  let type: EpisodeType
  let episodeNumber: Float?
  let isUnderProcessing: Bool

  static func == (lhs: EpisodePreview, rhs: EpisodePreview) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

func guessEpisodeReleaseWeekdayAndTime(in episodePreviews: [EpisodePreview]) -> (String, String)? {
  if episodePreviews.isEmpty {
    return nil
  }

  // Create a calendar instance
  let calendar = Calendar.current

  // Create a dictionary to store the count of occurrences for each weekday
  var weekdayCount = [Int: Int]()

  // Variables to calculate the average time
  var totalSeconds = 0
  var totalCount = 0

  let episodePreviewsToProcess =
    episodePreviews
    .filter { episodePreview in
      episodePreview.type != .trailer && episodePreview.uploadDate != nil
    }
    .reversed()
    .prefix(4)

  // Iterate through the array of dates
  for episodePreview in episodePreviewsToProcess {
    guard let uploadDate = episodePreview.uploadDate else {
      continue
    }

    // Get the weekday component of the date
    if let weekday = calendar.dateComponents([.weekday], from: uploadDate).weekday {
      // Increment the count for the current weekday
      weekdayCount[weekday, default: 0] += 1
    }

    // Extract time components
    let components = calendar.dateComponents([.hour, .minute, .second], from: uploadDate)

    // Calculate total seconds
    if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
      totalSeconds += hours * 3600 + minutes * 60 + seconds
      totalCount += 1
    }
  }

  // Find the weekday with the maximum count
  if let mostOccurringWeekday = weekdayCount.max(by: { $0.value < $1.value })?.key {
    // Convert the weekday to a string representation
    let weekdaySymbols = [
      0: "воскресеньям",
      1: "понедельникам",
      2: "вторникам",
      3: "средам",
      4: "четвергам",
      5: "пятницам",
      6: "субботам",
    ]

    guard let weekdayString = weekdaySymbols[mostOccurringWeekday - 1] else {
      return nil
    }

    // Calculate the average time
    if totalCount > 0 {
      let averageSeconds = totalSeconds / totalCount
      let averageTime = String(
        format: "%02d:%02d",
        averageSeconds / 3600,
        (averageSeconds % 3600) / 60
      )

      return (weekdayString, averageTime)
    }

    return nil
  }

  // Return nil for both if the array is empty
  return nil
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

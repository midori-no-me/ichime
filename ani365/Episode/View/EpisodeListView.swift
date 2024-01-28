import SwiftUI

struct EpisodeListView: View {
    public let episodePreviews: [EpisodePreview]
    public let lastEpisodeWatched: Int?

    var body: some View {
        List {
            Section {
                ForEach(self.episodePreviews, id: \.self) { episodePreview in
                    NavigationLink(destination: EpisodeTranslationsView(
                            episodeId: episodePreview.id,
                        episodeTitle: episodePreview.title ?? episodePreview.typeAndNumber
                        )) {
                        Label {
                            if let title = episodePreview.title {
                                Text(title)

                                Text(episodePreview.typeAndNumber)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(episodePreview.typeAndNumber)
                            }
                        } icon: {
                            Image(systemName: getLabelIconBasedOnWatchStatus(
                                episodePreview.episodeNumber,
                                lastEpisodeWatched,
                                episodePreview.type
                            ))
                        }
                        .badge(formatMovieReleaseDate2(episodePreview.uploadDate))
                    }
                    .swipeActions {
                        Button("Просмотрено") {
                            print("Awesome!")
                        }
                        .tint(.green)
                    }
                }
            } footer: {
                Text("Смахните справа налево, чтобы отметить серию просмотренной или не просмотренной.")
            }
        }
        .navigationTitle("Список серий")
        .navigationBarTitleDisplayMode(.large)
    }
}

enum EpisodeWatchStatus {
    case watched
    case notWatched
    case canNotBeMarkedAsWatched
}

func isEpisodeWatched(
    _ episodeNumber: Float?,
    _ lastEpisodeWatched: Int?,
    _ episodeType: EpisodeType
) -> EpisodeWatchStatus {
    guard let episodeNumber else {
        return .notWatched
    }

    guard let lastEpisodeWatched else {
        return .notWatched
    }

    if episodeType == .trailer {
        return .canNotBeMarkedAsWatched
    }

    // Check if episodeNumber is a round number
    if episodeNumber.truncatingRemainder(dividingBy: 1) != 0 {
        return .canNotBeMarkedAsWatched
    }

    return Float(lastEpisodeWatched) >= episodeNumber
        ? .watched
        : .notWatched
}

func getLabelIconBasedOnWatchStatus(
    _ episodeNumber: Float?,
    _ lastEpisodeWatched: Int?,
    _ episodeType: EpisodeType
) -> String {
    let watchStatus = isEpisodeWatched(
        episodeNumber,
        lastEpisodeWatched,
        episodeType
    )

    switch watchStatus {
    case .watched:
        return "circle.inset.filled"
    case .notWatched:
        return "circle.dotted"
    case .canNotBeMarkedAsWatched:
        return ""
    }
}

func formatMovieReleaseDate2(_ releaseDate: Date?) -> String {
    guard let releaseDate = releaseDate else {
        return ""
    }

    let now = Date()
    let calendar = Calendar.current

    if calendar.isDateInToday(releaseDate) || calendar.isDateInYesterday(releaseDate) {
        let formatStyle = Date.RelativeFormatStyle(presentation: .named)

        return releaseDate.formatted(formatStyle)
    } else {
        let formatter = DateFormatter()

        formatter.setLocalizedDateFormatFromTemplate("d MMMM")

        if !calendar.isDate(releaseDate, equalTo: now, toGranularity: .year) {
            formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        }

        return formatter.string(from: releaseDate)
    }
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data, lastEpisodeWatched: 3)
    }
}

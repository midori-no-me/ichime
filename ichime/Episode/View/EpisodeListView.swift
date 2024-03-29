import SwiftUI

struct EpisodeListView: View {
    public let episodePreviews: [EpisodePreview]

    var body: some View {
        List {
            ForEach(self.episodePreviews, id: \.self) { episodePreview in
                NavigationLink(destination: EpisodeTranslationsView(
                    episodeId: episodePreview.id,
                    episodeTitle: episodePreview.title ?? episodePreview.typeAndNumber
                )) {
                    EpisodePreviewRow(episodePreview: episodePreview)
                }
            }
        }
        #if os(tvOS)
        .listStyle(.grouped)
        #endif
        #if !os(tvOS)
        .navigationTitle("Список серий")
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

struct EpisodePreviewRow: View {
    let episodePreview: EpisodePreview

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        let releaseDateAndStatus = formatEpisodeReleaseDateAndStatus(
            episodePreview.uploadDate,
            episodePreview.isUnderProcessing
        )

        HStack {
            VStack(alignment: .leading) {
                if horizontalSizeClass == .compact {
                    Text(releaseDateAndStatus)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if let title = episodePreview.title {
                    Text(title)
                        + Text(" — \(episodePreview.typeAndNumber)")
                        .foregroundStyle(.secondary)
                } else {
                    Text(episodePreview.typeAndNumber)
                }
            }

            if horizontalSizeClass != .compact {
                Spacer()

                Text(releaseDateAndStatus)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private func formatEpisodeReleaseDateAndStatus(
    _ uploadDate: Date?,
    _ isUnderProcessing: Bool
) -> String {
    var dateString = formatRelativeDate(uploadDate)

    if isUnderProcessing {
        dateString += " (в обработке)"
    }

    return dateString
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data)
    }
}

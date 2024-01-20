//
//  EpisodePreview.swift
//  ani365
//
//  Created by p.flaks on 13.01.2024.
//

import SwiftUI

struct EpisodePreviewRow: View {
    let data: EpisodePreview

    var body: some View {
        if let title = data.title {
            EpisodePreviewRowWithTitle(
                title: title,
                typeAndNumber: data.typeAndNumber,
                uploadDate: data.uploadDate,
                isUnderProcessing: data.isUnderProcessing
            )
        } else {
            EpisodePreviewRowWithoutTitle(
                typeAndNumber: data.typeAndNumber,
                uploadDate: data.uploadDate,
                isUnderProcessing: data.isUnderProcessing
            )
        }
    }
}

struct EpisodePreviewRowWithTitle: View {
    let title: String
    let typeAndNumber: String
    let uploadDate: Date?
    let isUnderProcessing: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text([self.typeAndNumber, formatMovieReleaseDate(uploadDate)].formatted(.list(type: .and, width: .narrow)))
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(title)
        }
    }
}

struct EpisodePreviewRowWithoutTitle: View {
    let typeAndNumber: String
    let uploadDate: Date?
    let isUnderProcessing: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(formatMovieReleaseDate(uploadDate))
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(self.typeAndNumber)
        }
    }
}

func formatMovieReleaseDate(_ releaseDate: Date?) -> String {
    guard let releaseDate = releaseDate else {
        return "???"
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
    List {
        ForEach(EpisodePreviewSampleData.data, id: \.self) { episodePreview in
            EpisodePreviewRow(data: episodePreview)
        }
    }
}

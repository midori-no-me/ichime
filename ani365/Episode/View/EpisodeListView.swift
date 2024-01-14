//
//  EpisodeListView.swift
//  ani365
//
//  Created by p.flaks on 13.01.2024.
//

import SwiftUI

struct EpisodeListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public let episodePreviews: [EpisodePreview]

    var body: some View {
        Table(of: EpisodePreview.self) {
            TableColumn("Название серии") { episodePreview in
                if horizontalSizeClass == .compact {
                    EpisodePreviewRow(data: episodePreview)
                } else {
                    Text(episodePreview.title ?? episodePreview.typeAndNumber)
                }
            }

            TableColumn("Номер серии") { episodePreview in
                if episodePreview.type != .trailer, let episodeNumber = episodePreview.episodeNumber {
                    Text(episodeNumber.formatted())
                }
            }
            .alignment(.trailing)

            TableColumn("Дата выхода") { episodePreview in
                Text(formatMovieReleaseDate(episodePreview.uploadDate))
            }
            .alignment(.trailing)
        } rows: {
            ForEach(self.episodePreviews, id: \.self) { episodePreview in
                TableRow(episodePreview)
            }
        }
        .navigationTitle("Список серий")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data)
    }
}

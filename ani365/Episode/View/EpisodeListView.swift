//
//  EpisodeListView.swift
//  ani365
//
//  Created by p.flaks on 13.01.2024.
//

import SwiftUI

struct EpisodeListView: View {
    public let episodePreviews: [EpisodePreview]

    var body: some View {
        List {
            ForEach(self.episodePreviews, id: \.self) { episodePreview in
                EpisodePreviewRow(data: episodePreview)
            }
        }
        .navigationTitle("Список серий")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data)
    }
}

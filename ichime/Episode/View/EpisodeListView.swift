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
                    EpisodePreviewRow(data: episodePreview)
                }
            }
        }
        .navigationTitle("Список серий")
        #if !os(tvOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data)
    }
}

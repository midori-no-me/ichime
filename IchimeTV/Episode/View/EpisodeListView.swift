import SwiftUI

struct EpisodeListView: View {
    public let episodePreviews: [EpisodePreview]

    var body: some View {
        List {
            ForEach(self.episodePreviews, id: \.self) { episodePreview in
                NavigationLink(destination: Text("translation view")) {
                    EpisodePreviewRow(data: episodePreview)
                }
            }
        }
        .navigationTitle("Список серий")
    }
}

#Preview {
    NavigationStack {
        EpisodeListView(episodePreviews: EpisodePreviewSampleData.data)
    }
}

import SwiftUI

class EpisodeViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([(key: Translation.CompositeType, value: [Translation])])
    }

    @Published private(set) var state = State.idle

    public let episodeTitle: String

    private let episodeId: Int
    private let client: Anime365Client

    init(
        episodeId: Int,
        episodeTitle: String
    ) {
        self.episodeId = episodeId
        self.episodeTitle = episodeTitle
        self.client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )
    }

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad() async {
        await updateState(.loading)

        do {
            let episodeTranslations = try await client.getEpisodeTranslations(
                episodeId: episodeId
            )

            if episodeTranslations.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                await updateState(.loaded(getGroupedTranslations(episodeTranslations: episodeTranslations)))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    private func getGroupedTranslations(
        episodeTranslations: [Translation]
    ) -> [(key: Translation.CompositeType, value: [Translation])] {
        var translationsGroupedByLocalizedSection: [Translation.CompositeType: [Translation]] = [:]

        for episodeTranslation in episodeTranslations {
            translationsGroupedByLocalizedSection[episodeTranslation.getCompositeType(), default: []]
                .append(episodeTranslation)
        }

        for (sectionType, translations) in translationsGroupedByLocalizedSection {
            translationsGroupedByLocalizedSection[sectionType] = translations.sorted(
                by: { $0.translationTeam < $1.translationTeam }
            )
        }

        return translationsGroupedByLocalizedSection.sorted(by: { $0.0 < $1.0 })
    }
}

struct EpisodeTranslationsView: View {
    @ObservedObject var viewModel: EpisodeViewModel

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad()
                    }
                }

            case .loading:
                ProgressView()

            case .loadingFailed(let error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)

            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Скорее всего, у этой серии ещё нет переводов, либо они находятся в обработке")
                }

            case .loaded(let groupedTranslations):
                List {
                    ForEach(groupedTranslations, id: \.key) { translationGroup in
                        Section {
                            ForEach(translationGroup.value, id: \.id) { episodeTranslation in
                                TranslationRow(episodeTranslation: episodeTranslation)
                            }
                        } header: {
                            Text(translationGroup.key.getLocalizaedTranslation())
                        }
                    }
                }
            }
        }
        .navigationTitle(self.viewModel.episodeTitle)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct TranslationRow: View {
    let episodeTranslation: Translation

    @State private var showingSheet = false

    var body: some View {
        Button(action: {
            self.showingSheet.toggle()
        }) {
            VStack(alignment: .leading) {
                Text([self.episodeTranslation.sourceVideoQuality.getLocalizaedTranslation(), String(self.episodeTranslation.height) + "p"].formatted(.list(type: .and, width: .narrow)))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                Text(self.episodeTranslation.translationTeam)
            }
        }
        .sheet(isPresented: self.$showingSheet) {
            NavigationStack {
                EpisodeTranslationQualitySelectorView(
                    viewModel: .init(
                        translationId: episodeTranslation.id,
                        translationTeam: episodeTranslation.translationTeam
                    )
                )
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeTranslationsView(viewModel: .init(
            episodeId: 291395,
            episodeTitle: "69 серия"
        ))
    }
}

import SwiftUI

@Observable
class EpisodeViewModel {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([(key: Translation.CompositeType, value: [Translation])])
    }

    private(set) var state = State.idle

    private let client: Anime365Client

    init(
        client: Anime365Client = ApplicationDependency.container.resolve()
    ) {
        self.client = client
    }

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad(episodeId: Int) async {
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
    let episodeId: Int
    let episodeTitle: String

    @State private var viewModel: EpisodeViewModel = .init()
    @StateObject private var videoPlayerController: VideoPlayerController = .init()

    var body: some View {
        ZStack {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad(episodeId: episodeId)
                    }
                }

            case .loading:
                ProgressView()

            case let .loadingFailed(error):
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

            case let .loaded(groupedTranslations):
                List {
                    ForEach(groupedTranslations, id: \.key) { translationGroup in
                        Section {
                            ForEach(translationGroup.value, id: \.id) { episodeTranslation in
                                TranslationRow(
                                    episodeTranslation: episodeTranslation,
                                    videoPlayerController: videoPlayerController
                                )
                            }
                        } header: {
                            Text(translationGroup.key.getLocalizaedTranslation())
                        }
                    }
                }
            }

            if videoPlayerController.loading {
                VideoPlayerLoader()
            }
        }
        .navigationTitle(episodeTitle)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct TranslationRow: View {
    let episodeTranslation: Translation
    @ObservedObject var videoPlayerController: VideoPlayerController

    @State private var showingSheet = false

    var body: some View {
        Button(action: {
            self.showingSheet.toggle()
        }) {
            Text(self.episodeTranslation.translationTeam)
        }
        .badge([
            String(self.episodeTranslation.height) + "p",
            self.episodeTranslation.sourceVideoQuality.getLocalizaedTranslation()
        ].formatted(.list(type: .and, width: .narrow)))
        .sheet(isPresented: self.$showingSheet) {
            NavigationStack {
                EpisodeTranslationQualitySelectorView(
                    translationId: episodeTranslation.id,
                    translationTeam: episodeTranslation.translationTeam,
                    videoPlayerController: videoPlayerController
                )
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeTranslationsView(
            episodeId: 291_395,
            episodeTitle: "69 серия"
        )
    }
}

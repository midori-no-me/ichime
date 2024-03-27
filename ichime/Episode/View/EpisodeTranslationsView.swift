import SwiftUI

typealias GroupedTranslation = [(key: Translation.CompositeType, value: [Translation])]

@Observable
class EpisodeViewModel {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded(GroupedTranslation)
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
    ) -> GroupedTranslation {
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
    var preselectedTranslation: Int? = nil

    @State private var viewModel: EpisodeViewModel = .init()

    var body: some View {
        Group {
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
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif

            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Скорее всего, у этой серии ещё нет переводов, либо они находятся в обработке")
                }

            case let .loaded(groupedTranslations):
                List {
                    if let preselectedTranslation, let translation = findTranslation(
                        id: preselectedTranslation,
                        groupedTranslations: groupedTranslations
                    ) {
                        Section {
                            TranslationRow(
                                episodeId: episodeId,
                                episodeTranslation: translation
                            )
                        } header: {
                            Text("Последний раз смотрели")
                        }
                    }

                    ForEach(groupedTranslations, id: \.key) { translationGroup in
                        Section {
                            ForEach(translationGroup.value, id: \.id) { episodeTranslation in
                                TranslationRow(
                                    episodeId: episodeId,
                                    episodeTranslation: episodeTranslation
                                )
                            }
                        } header: {
                            Text(translationGroup.key.getLocalizedTranslation())
                        }
                    }
                }
            }
        }
        #if os(tvOS)
        .listStyle(.grouped)
        #endif
        #if !os(tvOS)
        .navigationTitle(episodeTitle)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    func findTranslation(id: Int, groupedTranslations: GroupedTranslation) -> Translation? {
        for group in groupedTranslations {
            if let translation = group.value.first(where: { $0.id == id }) {
                return translation
            }
        }
        return nil
    }
}

private struct TranslationRow: View {
    let episodeId: Int
    let episodeTranslation: Translation

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var showingSheet = false

    var body: some View {
        Button(action: {
            self.showingSheet.toggle()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    if horizontalSizeClass == .compact {
                        Text(formatTranslationQuality(episodeTranslation, qualityNameFirst: false))
                            .foregroundStyle(Color.secondary)
                            .font(.caption)
                    }

                    Text(self.episodeTranslation.translationTeam)
                }

                if horizontalSizeClass != .compact {
                    Spacer()

                    Text(formatTranslationQuality(episodeTranslation, qualityNameFirst: true))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                EpisodeTranslationQualitySelectorView(
                    episodeId: episodeId,
                    translationId: episodeTranslation.id,
                    translationTeam: episodeTranslation.translationTeam
                )
            }
            .presentationDetents([.medium])
        }
    }
}

private func formatTranslationQuality(
    _ translation: Translation,
    qualityNameFirst: Bool
) -> String {
    var stringComponents = [String(translation.height) + "p"]

    if translation.sourceVideoQuality != .tv {
        stringComponents.append(translation.sourceVideoQuality.getLocalizedTranslation())
    }

    if qualityNameFirst {
        stringComponents.reverse()
    }

    return stringComponents.joined(separator: " • ")
}

#Preview {
    NavigationStack {
        EpisodeTranslationsView(
            episodeId: 291_395,
            episodeTitle: "69 серия"
        )
    }
}

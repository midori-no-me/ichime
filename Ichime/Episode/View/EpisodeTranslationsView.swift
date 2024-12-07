import ScraperAPI
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
  private(set) var preselectedTranslation: Translation?

  private let client: Anime365Client
  private let scraper: ScraperAPI.APIClient

  init(
    client: Anime365Client = ApplicationDependency.container.resolve(),
    scraper: ScraperAPI.APIClient = ApplicationDependency.container.resolve()
  ) {
    self.client = client
    self.scraper = scraper
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
      }
      else {
        await updateState(.loaded(getGroupedTranslations(episodeTranslations: episodeTranslations)))

        await getRecommendation(translations: episodeTranslations)
      }
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func getRecommendation(translations: [Translation]) async {
    guard let translation = translations.first else {
      return
    }

    guard
      let recommendation =
        try? await scraper
        .sendAPIRequest(
          ScraperAPI.Request.GetRecommendTranslation(episodeURL: translation.translationUrl)
        )
    else {
      return
    }

    withAnimation {
      preselectedTranslation = translations.first(where: { $0.id == recommendation })
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
          .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Скорее всего, у этой серии ещё нет переводов, либо они находятся в обработке")
        }

      case let .loaded(groupedTranslations):
        List {
          Section {
            if let preselectedTranslation = viewModel.preselectedTranslation {
              TranslationRow(
                episodeId: episodeId,
                episodeTranslation: preselectedTranslation,
                isRecommendedTranslation: true
              )
            }
            else {
              ProgressView()
            }
          } header: {
            Text("Рекомендованный перевод")
          }

          ForEach(groupedTranslations, id: \.key) { translationGroup in
            Section {
              ForEach(translationGroup.value, id: \.id) { episodeTranslation in
                TranslationRow(
                  episodeId: episodeId,
                  episodeTranslation: episodeTranslation,
                  isRecommendedTranslation: false
                )
              }
            } header: {
              Text(translationGroup.key.getLocalizedTranslation())
            }
          }
        }
      }
    }
    .listStyle(.grouped)

  }
}

private struct TranslationRow: View {
  let episodeId: Int
  let episodeTranslation: Translation
  let isRecommendedTranslation: Bool

  @State private var showingSheet = false

  var body: some View {
    Button(action: {
      self.showingSheet.toggle()
      updateLastSelectedTranslation()
    }) {
      HStack {
        VStack(alignment: .leading) {
          Text(self.episodeTranslation.translationTeam)
            .lineLimit(isRecommendedTranslation ? 1 : nil)
            .truncationMode(.tail)
        }

        Spacer()

        Text(
          formatTranslationQuality(
            episodeTranslation,
            qualityNameFirst: true,
            displayTranslationType: isRecommendedTranslation
          )
        )
        .foregroundStyle(Color.secondary)
        .lineLimit(isRecommendedTranslation ? 1 : nil)
        .truncationMode(.tail)
      }
    }
    .sheet(isPresented: $showingSheet) {
      NavigationStack {
        EpisodeTranslationQualitySelectorView(
          episodeId: episodeId,
          translationId: episodeTranslation.id,
          translationTeam: episodeTranslation.translationTeam,
          disableSubs: episodeTranslation.translationMethod == .voiceover
        )
      }
      .presentationDetents([.medium])
    }
  }

  func updateLastSelectedTranslation() {
    let session: ScraperAPI.Session = ApplicationDependency.container.resolve()

    session.set(
      name: .lastTranslationType,
      value: episodeTranslation.getCompositeType().translationTypeForCookie
    )
  }
}

private func formatTranslationQuality(
  _ translation: Translation,
  qualityNameFirst: Bool,
  displayTranslationType: Bool
) -> String {
  var stringComponents = [String(translation.height) + "p"]

  if translation.sourceVideoQuality != .tv {
    stringComponents.append(translation.sourceVideoQuality.getLocalizedTranslation())
  }

  if displayTranslationType {
    stringComponents.append(translation.getCompositeType().getLocalizedTranslation())
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

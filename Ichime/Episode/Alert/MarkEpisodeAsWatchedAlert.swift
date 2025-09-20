import SwiftUI

private struct MarkEpisodeAsWatchedAlert: ViewModifier {
  @State private var showAlert: Bool = false
  @State private var showTitleRomaji: String? = nil
  @State private var showTitleRussian: String? = nil
  @State private var episodeTitle: String? = nil

  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationId: Int = 0

  private let episodeService: EpisodeService = ApplicationDependency.container.resolve()
  private let anime365KitFactory: Anime365KitFactory = ApplicationDependency.container.resolve()

  func body(content: Content) -> some View {
    content
      .onAppear {
        if self.lastWatchedTranslationId != 0 {
          Task {
            do {
              let (episodeTitle, showTitleRomaji, showTitleRussian) =
                try await episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationId: self.lastWatchedTranslationId
                )

              self.showTitleRomaji = showTitleRomaji
              self.showTitleRussian = showTitleRussian
              self.episodeTitle = episodeTitle
            }
            catch {
              self.showTitleRomaji = nil
              self.showTitleRussian = nil
              self.episodeTitle = nil
            }

            self.showAlert = true
          }
        }
      }
      .onChange(of: self.lastWatchedTranslationId) {
        if self.lastWatchedTranslationId != 0 {
          Task {
            do {
              let (episodeTitle, showTitleRomaji, showTitleRussian) =
                try await episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationId: self.lastWatchedTranslationId
                )

              self.showTitleRomaji = showTitleRomaji
              self.showTitleRussian = showTitleRussian
              self.episodeTitle = episodeTitle
            }
            catch {
              self.showTitleRomaji = nil
              self.showTitleRussian = nil
              self.episodeTitle = nil
            }

            self.showAlert = true
          }
        }
      }
      .alert(
        self.episodeTitle ?? "Последняя просмотренная серия",
        isPresented: self.$showAlert,
        presenting: self.lastWatchedTranslationId
      ) { _ in
        Button {
          Task {
            try? await self.anime365KitFactory.createWebClient().markEpisodeAsWatched(
              translationID: self.lastWatchedTranslationId
            )

            self.lastWatchedTranslationId = 0
          }
        } label: {
          Text("Отметить просмотренной")
        }

        Button(role: .cancel) {
          self.lastWatchedTranslationId = 0
        } label: {
          Text("Закрыть")
        }
      } message: { _ in
        if let showTitle = getShowTitleForAlert() {
          Text(showTitle)
        }
      }
  }

  private func getShowTitleForAlert() -> String? {
    var titles: [String] = []

    if let showTitleRomaji {
      titles.append(showTitleRomaji)
    }

    if let showTitleRussian {
      titles.append(showTitleRussian)
    }

    if titles.isEmpty {
      return nil
    }

    return titles.joined(separator: "\n")
  }
}

extension View {
  func markEpisodeAsWatchedAlert() -> some View {
    modifier(MarkEpisodeAsWatchedAlert())
  }
}

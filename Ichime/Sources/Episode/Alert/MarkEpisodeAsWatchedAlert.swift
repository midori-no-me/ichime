import IchimeAnime365
import IchimeEpisode
import SwiftUI

private struct MarkEpisodeAsWatchedAlert: ViewModifier {
  // MARK: SwiftUI Properties

  @State private var showAlert: Bool = false
  @State private var showTitleRomaji: String? = nil
  @State private var showTitleRussian: String? = nil
  @State private var episodeTitle: String? = nil

  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationID: Int = 0

  @Environment(\.dependencies) private var dependencies

  // MARK: Content Methods

  func body(content: Content) -> some View {
    content
      .onAppear {
        if self.lastWatchedTranslationID != 0 {
          Task {
            do {
              let (episodeTitle, showTitleRomaji, showTitleRussian) =
                try await self.dependencies.episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationID: self.lastWatchedTranslationID
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
      .onChange(of: self.lastWatchedTranslationID) {
        if self.lastWatchedTranslationID != 0 {
          Task {
            do {
              let (episodeTitle, showTitleRomaji, showTitleRussian) =
                try await self.dependencies.episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationID: self.lastWatchedTranslationID
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
        presenting: self.lastWatchedTranslationID
      ) { _ in
        Button {
          Task {
            try? await self.dependencies.anime365KitFactory.createWebClient().markEpisodeAsWatched(
              translationID: self.lastWatchedTranslationID
            )

            self.lastWatchedTranslationID = 0
          }
        } label: {
          Text("Отметить просмотренной")
        }

        Button(role: .cancel) {
          self.lastWatchedTranslationID = 0
        } label: {
          Text("Закрыть")
        }
      } message: { _ in
        if let showTitle = getShowTitleForAlert() {
          Text(showTitle)
        }
      }
  }

  // MARK: Functions

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

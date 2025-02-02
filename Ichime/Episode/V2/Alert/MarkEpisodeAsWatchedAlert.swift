import ScraperAPI
import SwiftUI

private struct MarkEpisodeAsWatchedAlert: ViewModifier {
  @State private var showAlert: Bool = false
  @State private var showTitle: String? = nil
  @State private var episodeTitle: String? = nil

  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationId: Int = 0

  private let episodeService: EpisodeService = ApplicationDependency.container.resolve()
  private let scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()

  func body(content: Content) -> some View {
    content
      .onAppear {
        if self.lastWatchedTranslationId != 0 {
          Task {
            do {
              let (episodeTitle, showTitle) =
                try await episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationId: self.lastWatchedTranslationId
                )

              self.showTitle = showTitle
              self.episodeTitle = episodeTitle
            }
            catch {
              self.showTitle = nil
              self.episodeTitle = nil
            }

            self.showAlert = true
          }
        }
      }
      .onChange(of: self.lastWatchedTranslationId) {
        print(self.lastWatchedTranslationId)
        if self.lastWatchedTranslationId != 0 {
          Task {
            do {
              let (episodeTitle, showTitle) =
                try await episodeService.getTranslationInfoForMarkingEpisodeAsWatchedAlert(
                  translationId: self.lastWatchedTranslationId
                )

              self.showTitle = showTitle
              self.episodeTitle = episodeTitle
            }
            catch {
              self.showTitle = nil
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
            try? await self.scraperClient.sendAPIRequest(
              ScraperAPI.Request
                .UpdateCurrentWatch(translationId: self.lastWatchedTranslationId)
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
        if let showTitle {
          Text(showTitle)
        }
      }
  }
}

extension View {
  func markEpisodeAsWatchedAlert() -> some View {
    modifier(MarkEpisodeAsWatchedAlert())
  }
}

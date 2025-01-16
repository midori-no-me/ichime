import ScraperAPI
import SwiftUI

@Observable
class ShowMomentsCardsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([ScraperAPI.Types.Moment])
  }

  private(set) var state: State = .idle

  private let api: ScraperAPI.APIClient
  private let videoHolder: VideoPlayerHolder

  init(
    scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    videoPlayerHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()
  ) {
    self.api = scraperClient
    self.videoHolder = videoPlayerHolder
  }

  func performInitialLoad(showId: Int) async {
    self.state = .loading

    await self.performPullToRefresh(showId: showId)
  }

  func performPullToRefresh(showId: Int) async {
    do {
      let moments = try await api.sendAPIRequest(
        ScraperAPI.Request.GetMomentsByShow(showId: showId)
      )

      if moments.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(moments)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func showMoment(id: Int, showName: String) async {
    do {
      let embed = try await api.sendAPIRequest(ScraperAPI.Request.GetMomentEmbed(momentId: id))

      guard let video = embed.video.first,
        let videoHref = video.urls.first,
        let videoURL = URL(string: videoHref)
      else {
        return
      }

      await self.videoHolder.play(
        video: .init(
          videoURL: videoURL,
          subtitleURL: nil,
          metadata: .init(
            title: embed.title,
            subtitle: showName,
            description: nil,
            genre: nil,
            image: nil,
            year: nil
          ),
          translationId: nil
        )
      )
    }
    catch {
      print(error)
    }
  }

  public func getShowMomentsFetchFunction(showId: Int) -> (_ page: Int) async throws -> [ScraperAPI
    .Types.Moment]
  {
    func fetchFunction(_ page: Int) async throws -> [ScraperAPI.Types.Moment] {
      try await self.api.sendAPIRequest(
        ScraperAPI.Request.GetMomentsByShow(showId: showId, page: page)
      )
    }

    return fetchFunction
  }
}

struct ShowMomentsCardsView: View {
  private static let SPACING_BETWEEN_TITLE_AND_CARDS: CGFloat = 50

  let showId: Int
  let showName: String
  @State var viewModel: ShowMomentsCardsViewModel = .init()

  var body: some View {
    VStack(alignment: .leading, spacing: ShowMomentsCardsView.SPACING_BETWEEN_TITLE_AND_CARDS) {
      SectionHeader(
        title: "Моменты",
        subtitle: nil
      ) {
        MomentsView(
          viewModel: .init(
            fetchMoments: self.viewModel.getShowMomentsFetchFunction(showId: self.showId)
          ),
          title: "Моменты",
          description: self.showName
        )
      }

      Group {
        switch self.viewModel.state {
        case .idle:
          Color.clear.onAppear {
            Task {
              await self.viewModel.performInitialLoad(showId: self.showId)
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
          .focusable()

        case .loadedButEmpty:
          ContentUnavailableView {
            Label("Ничего не нашлось", systemImage: "list.bullet")
          } description: {
            Text("Возможно, это баг")
          }
          .focusable()

        case let .loaded(moments):
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
              ForEach(moments) { moment in
                MomentCard(
                  title: moment.title,
                  cover: moment.preview,
                  websiteUrl: URL(string: "https://anime365.ru/moments/219167")!,
                  id: moment.id
                ) {
                  Task {
                    await self.viewModel.showMoment(id: moment.id, showName: self.showName)
                  }
                }
              }
            }
          }
          .scrollClipDisabled(true)
        }
      }
    }
  }
}

#Preview {
  ShowMomentsCardsView(showId: 8762, showName: "One piece")
}

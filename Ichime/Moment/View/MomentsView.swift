import ScraperAPI
import SwiftUI

class MomentsViewModel: ObservableObject {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([ScraperAPI.Types.Moment])
  }

  @Published private(set) var state = State.idle

  private var currentPage: Int = 1
  private var moments: [ScraperAPI.Types.Moment] = []
  private var stopLazyLoading: Bool = false
  private let fetchMoments: (_ page: Int) async throws -> [ScraperAPI.Types.Moment]
  private let videoHolder: VideoPlayerHolder
  private let api: ScraperAPI.APIClient

  init(
    fetchMoments: @escaping (_ page: Int) async throws -> [ScraperAPI.Types.Moment],
    scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    videoPlayerHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()
  ) {
    self.fetchMoments = fetchMoments
    videoHolder = videoPlayerHolder
    api = scraperClient
  }

  @MainActor
  func updateState(_ newState: State) {
    state = newState
  }

  func performInitialLoad() async {
    await updateState(.loading)

    do {
      let moments = try await fetchMoments(
        currentPage
      )

      if moments.isEmpty {
        await updateState(.loadedButEmpty)
      }
      else {
        currentPage += 1
        self.moments = moments
        await updateState(.loaded(self.moments))
      }
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performLazyLoading() async {
    if stopLazyLoading {
      return
    }

    do {
      let moments = try await fetchMoments(
        currentPage
      )

      if moments.isEmpty {
        stopLazyLoading = true
      }

      currentPage += 1
      self.moments += moments
      await updateState(.loaded(self.moments))
    }
    catch {
      stopLazyLoading = true
    }
  }

  func performPullToRefresh() async {
    do {
      let moments = try await fetchMoments(
        1
      )

      if moments.isEmpty {
        await updateState(.loadedButEmpty)
      }
      else {
        currentPage = 2
        self.moments = moments
        await updateState(.loaded(self.moments))
      }
    }
    catch {
      await updateState(.loadingFailed(error))
    }

    stopLazyLoading = false
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

      await videoHolder.play(
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
}

struct MomentsView: View {
  @StateObject public var viewModel: MomentsViewModel

  public let title: String
  public let description: String?

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
          .focusable()

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
        ScrollView([.vertical]) {
          Group {
            Text(title)
              .font(.title2)

            if let description {
              Text(description)
                .font(.title3)

                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          LazyVGrid(
            columns: [
              GridItem(
                .adaptive(minimum: MomentCard.RECOMMENDED_MINIMUM_WIDTH),
                spacing: MomentCard.RECOMMENDED_SPACING,
                alignment: .center
              )
            ],
            spacing: MomentCard.RECOMMENDED_SPACING
          ) {
            ForEach(moments) { moment in
              MomentCard(
                title: moment.title,
                cover: moment.preview,
                websiteUrl: URL(string: "https://anime365.ru/moments/219167")!,
                id: moment.id
              ) {
                Task {
                  await viewModel.showMoment(id: moment.id, showName: "show name")
                }
              }
              .task {
                if moment == moments.last {
                  await self.viewModel.performLazyLoading()
                }
              }
            }
          }
          .padding(.top, 8)
          .scenePadding(.bottom)
        }
      }
    }
    .refreshable {
      await self.viewModel.performPullToRefresh()
    }
  }
}

// #Preview {
//    NavigationStack {
//        FilteredShowsView()
//    }
// }

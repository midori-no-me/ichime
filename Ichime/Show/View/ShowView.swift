import ScraperAPI
import SwiftData
import SwiftUI

typealias UserRateStatus = ScraperAPI.Types.UserRateStatus
extension ScraperAPI.Types.UserRateStatus {
  var imageInDropdown: String {
    switch self {
    case .deleted: return "trash"
    case .planned: return "hourglass"
    case .watching: return "eye.fill"
    case .completed: return "checkmark"
    case .onHold: return "pause.fill"
    case .dropped: return "archivebox.fill"
    }
  }

  var imageInToolbar: String {
    switch self {
    case .deleted: return "plus.circle"
    case .planned: return "hourglass.circle.fill"
    case .watching: return "eye.circle.fill"
    case .completed: return "checkmark.circle.fill"
    case .onHold: return "pause.circle.fill"
    case .dropped: return "archivebox.circle.fill"
    }
  }
}

@Observable
class ShowViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(Show)
  }

  private(set) var state = State.idle
  private var userRate: ScraperAPI.Types.UserRate?
  var showRateStatus: UserRateStatus {
    if let userRate {
      return userRate.status
    }
    else {
      return .deleted
    }
  }

  var statusReady: Bool {
    userRate != nil
  }

  private let client: Anime365Client
  private let scraperClient: ScraperAPI.APIClient
  private let dbService: DbService
  private var showId: Int = 0

  var shareUrl: URL {
    getWebsiteUrlByShowId(showId: showId)
  }

  init(
    client: Anime365Client = ApplicationDependency.container.resolve(),
    scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    dbService: DbService = ApplicationDependency.container.resolve()
  ) {
    self.client = client
    self.scraperClient = scraperClient
    self.dbService = dbService
  }

  func performInitialLoad(showId: Int, preloadedShow: Show?) async {
    state = .loading

    self.showId = showId

    do {
      if let preloadedShow {
        state = .loaded(preloadedShow)
      }
      else {
        //        let showFromDb = try await dbService.getAnime(id: showId)
        //
        //        if let showFromDb {
        //          state = .loaded(.init(from: showFromDb))
        //        }
        //        else {
        //          let show = try await client.getShow(
        //            seriesId: showId
        //          )
        //
        //          state = .loaded(show)
        //        }

        let show = try await client.getShow(
          seriesId: showId
        )

        state = .loaded(show)

      }

      await getUserRate(showId: showId)
    }
    catch {
      state = .loadingFailed(error)
    }
  }

  func performPullToRefresh() async {
    do {
      let show = try await client.getShow(
        seriesId: showId
      )

      await getUserRate(showId: showId)

      state = .loaded(show)
    }
    catch {
      state = .loadingFailed(error)
    }
  }

  private func getUserRate(showId: Int) async {
    do {
      userRate = try await scraperClient.sendAPIRequest(
        ScraperAPI.Request.GetUserRate(showId: showId, fullCheck: true)
      )
    }
    catch {
      print("\(error.localizedDescription)")
    }
  }

  func addToList() async {
    let request = ScraperAPI.Request.UpdateUserRate(
      showId: showId,
      userRate: .init(
        score: userRate?.score ?? 0,
        currentEpisode: userRate?.currentEpisode ?? 0,
        status: .planned,
        comment: ""
      )
    )

    do {
      userRate = try await scraperClient.sendAPIRequest(request)
    }
    catch {
      print("\(error.localizedDescription)")
    }
  }
}

struct ShowView: View {
  var showId: Int
  var preloadedShow: Show?

  @State private var viewModel: ShowViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              showId: self.showId,
              preloadedShow: self.preloadedShow
            )
          }
        }

      case .loading:
        ProgressView()
          .focusable()
          .centeredContentFix()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
        .focusable()

      case let .loaded(show):
        ScrollView(.vertical) {
          ShowDetails(show: show, viewModel: self.viewModel)
        }
      }
    }
    .refreshable {
      await self.viewModel.performPullToRefresh()
    }
  }
}
private let SPACING_BETWEEN_SECTIONS: CGFloat = 50

private struct ShowDetails: View {
  let show: Show
  var viewModel: ShowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
      ShowKeyDetailsSection(show: show, viewModel: viewModel)

      if !show.descriptions.isEmpty {
        ShowDescriptionCards(descriptions: show.descriptions)
      }

      ShowMomentsCardsView(showId: show.id, showName: show.title.compose)
    }
  }
}

private struct ShowKeyDetailsSection: View {
  let show: Show
  var viewModel: ShowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {

      HStack(alignment: .top, spacing: SPACING_BETWEEN_SECTIONS) {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
          ShowPrimaryAndSecondaryTitles(title: show.title)

          ShowActionButtons(show: show, viewModel: viewModel)

          LazyVGrid(
            columns: [
              GridItem(.flexible(), spacing: 18, alignment: .topLeading)
            ],
            spacing: 18
          ) {
            ShowProperty(
              label: "Рейтинг",
              value: self.show
                .score != nil
                ? "★ \(self.show.score!.formatted(.number.precision(.fractionLength(2))))" : "???",
              isInteractive: false
            )

            ShowProperty(
              label: "Тип",
              value: self.show.typeTitle,
              isInteractive: false
            )

            EpisodesShowProperty(
              totalEpisodes: self.show.numberOfEpisodes,
              episodePreviews: self.show.episodePreviews,
              isOngoing: self.show.isOngoing
            )

            if let airingSeason = self.show.airingSeason {
              SeasonShowProperty(airingSeason: airingSeason)
            }
            else {
              ShowProperty(
                label: "Сезон",
                value: "???",
                isInteractive: false
              )
            }

            if !self.show.genres.isEmpty {
              GenresShowProperty(showTitle: self.show.title, genres: self.show.genres)
            }
          }

        }

        if let posterUrl = self.show.posterUrl {
          Button(action: {}) {
            GeometryReader { geometry in
              AsyncImage(
                url: posterUrl,
                transaction: .init(animation: .easeInOut(duration: 0.5)),
                content: { phase in
                  switch phase {
                  case .empty:
                    EmptyView()
                  case let .success(image):
                    image.resizable()
                      .aspectRatio(contentMode: .fit)
                  case .failure:
                    EmptyView()
                  @unknown default:
                    EmptyView()
                  }
                }
              )
              .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
            }
          }
          .buttonStyle(.borderless)
        }
      }

    }
    .focusSection()

  }
}

private struct ShowPrimaryAndSecondaryTitles: View {
  let title: Show.Title

  var body: some View {
    VStack {
      Group {
        if title.translated.japaneseRomaji == nil || title.translated.russian == nil {
          Text(title.full)
            .font(.title2)
        }

        if let japaneseRomajiTitle = title.translated.japaneseRomaji {
          Text(japaneseRomajiTitle)
            .font(.title2)
        }

        if let russianTitle = title.translated.russian {
          Text(russianTitle)
            .font(.title3)
            .foregroundStyle(.secondary)
        }
      }
      .lineLimit(2)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct ShowActionButtons: View {
  let show: Show
  var viewModel: ShowViewModel
  @State var showEdit = false
  private let SPACING_BETWEEN_BUTTONS: CGFloat = 40

  var isInMyList: Bool {
    viewModel.showRateStatus != UserRateStatus.deleted
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: SPACING_BETWEEN_BUTTONS) {
        NavigationLink(
          destination: EpisodeListView(episodePreviews: self.show.episodePreviews)
        ) {
          Label(
            "Смотреть",
            systemImage: show.episodePreviews.isEmpty ? "play.slash.fill" : "play.fill"
          )
        }
        .buttonStyle(.bordered)

        .disabled(show.episodePreviews.isEmpty)

        if viewModel.statusReady {
          Button(action: {
            if isInMyList {
              showEdit = true
            }
            else {
              Task {
                await viewModel.addToList()
              }
            }
          }) {
            if isInMyList {
              Label(
                self.viewModel.showRateStatus.statusDisplayName,
                systemImage: self.viewModel.showRateStatus.imageInToolbar
              )
            }
            else {
              Label(
                UserRateStatus.deleted.statusDisplayName,
                systemImage: UserRateStatus.deleted.imageInToolbar
              )
            }
          }
          .buttonStyle(.bordered)
        }
      }
      .focusSection()

      Group {
        if !show.episodePreviews.isEmpty && show.isOngoing,
          let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: show.episodePreviews)
        {
          Text(
            "Обычно новые серии выходят по \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1)."
          )
        }

        if show.episodePreviews.isEmpty {
          Text(
            "У этого тайтла пока что нет загруженных серий."
          )
        }
      }
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.caption)
    }
    .sheet(
      isPresented: $showEdit,
      content: {
        MyListEditView(
          show: .init(
            id: show.id,
            name: show.title.compose,
            totalEpisodes: show.numberOfEpisodes ?? nil
          ),
          onUpdate: {
            Task {
              await self.viewModel.performPullToRefresh()
            }
          }
        )
      }
    )
  }
}

private struct ShowProperty: View {
  let label: String
  let value: String
  let isInteractive: Bool

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center, spacing: 4) {
        Text(self.label)
          .foregroundStyle(.secondary)
          .font(.caption)
          .fontWeight(.medium)

      }

      Text(self.value)
        .font(.caption)
    }
  }
}

private struct SeasonShowProperty: View {
  let airingSeason: AiringSeason
  let client: Anime365Client

  init(
    airingSeason: AiringSeason,
    client: Anime365Client = ApplicationDependency.container.resolve()
  ) {
    self.airingSeason = airingSeason
    self.client = client
  }

  var body: some View {
    NavigationLink(
      destination: FilteredShowsView(
        viewModel: .init(fetchShows: getShowsBySeason()),
        title: airingSeason.getLocalizedTranslation(),
        description: nil,
        displaySeason: false
      )
    ) {
      ShowProperty(
        label: "Сезон",
        value: airingSeason.getLocalizedTranslation(),
        isInteractive: true
      )
    }
    .buttonStyle(.plain)
  }

  private func getShowsBySeason() -> (_ offset: Int, _ limit: Int) async throws -> [Show] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [Show] {
      try await client.getSeason(
        offset: offset,
        limit: limit,
        airingSeason: airingSeason
      )
    }

    return fetchFunction
  }
}

private struct GenresShowProperty: View {
  let showTitle: Show.Title
  let genres: [Show.Genre]

  var body: some View {
    NavigationLink(
      destination: ShowGenreListView(
        showTitle: showTitle,
        genres: genres
      )
    ) {
      ShowProperty(
        label: "Жанры",
        value:
          genres
          .map { genre in genre.title }
          .formatted(.list(type: .and, width: .narrow)),
        isInteractive: true
      )
    }
    .buttonStyle(.plain)
  }
}

private struct EpisodesShowProperty: View {
  let totalEpisodes: Int?
  let episodePreviews: [EpisodePreview]
  let isOngoing: Bool

  var body: some View {
    ShowProperty(
      label: "Количество эпизодов",
      value: formatString(),
      isInteractive: false
    )
  }

  private func formatString() -> String {
    let latestEpisodeNumber = getLatestEpisodeNumber()

    if isOngoing {
      return "Вышло \(latestEpisodeNumber.formatted()) из \(totalEpisodes?.formatted() ?? "???")"
    }

    if let totalEpisodes {
      return totalEpisodes.formatted()
    }

    return "???"
  }

  private func getLatestEpisodeNumber() -> Float {
    let filteredAndSortedEpisodes =
      episodePreviews
      .filter { episodePreview in episodePreview.type != .trailer }
      .filter { episodePreview in episodePreview.episodeNumber != nil }
      .filter { episodePreview in episodePreview.episodeNumber! > 0 }
      .filter { episodePreview in
        episodePreview.episodeNumber!.truncatingRemainder(dividingBy: 1) == 0
      }  // remove episodes with non-round number like 35.5
      .sorted(by: { $0.episodeNumber! > $1.episodeNumber! })

    if filteredAndSortedEpisodes.isEmpty {
      return 0
    }

    return filteredAndSortedEpisodes[0].episodeNumber ?? 0
  }
}

private struct ShowDescriptionCards: View {
  let descriptions: [Show.Description]

  var body: some View {
    LazyVGrid(
      columns: [
        GridItem(
          .adaptive(minimum: CardWithExpandableText.RECOMMENDED_MINIMUM_WIDTH),
          spacing: CardWithExpandableText.RECOMMENDED_SPACING
        )
      ],
      spacing: CardWithExpandableText.RECOMMENDED_SPACING
    ) {
      ForEach(descriptions, id: \.self) { description in
        CardWithExpandableText(
          title: "Описание от \(description.source)",
          text: description.text
        )
      }
    }
    .focusSection()

  }
}

#Preview {
  NavigationStack {
    ShowView(showId: 8762)
  }
}

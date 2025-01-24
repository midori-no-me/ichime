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
    case loaded(ShowFull)
  }

  private(set) var state: State = .idle

  private var userRate: ScraperAPI.Types.UserRate?
  private let showService: ShowService
  private let scraperClient: ScraperAPI.APIClient
  private var showId: Int = 0

  var showRateStatus: UserRateStatus {
    if let userRate {
      return userRate.status
    }
    else {
      return .deleted
    }
  }

  var statusReady: Bool {
    self.userRate != nil
  }

  var shareUrl: URL {
    getWebsiteUrlByShowId(showId: self.showId)
  }

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
    self.scraperClient = scraperClient
  }

  func performInitialLoad(showId: Int) async {
    self.state = .loading

    self.showId = showId

    do {
      let show = try await showService.getFullShow(
        showId: showId
      )

      self.state = .loaded(show)

      await self.getUserRate(showId: showId)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performPullToRefresh() async {
    do {
      let show = try await showService.getFullShow(
        showId: self.showId
      )

      await self.getUserRate(showId: self.showId)

      self.state = .loaded(show)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func addToList() async {
    let request = ScraperAPI.Request.UpdateUserRate(
      showId: self.showId,
      userRate: .init(
        score: self.userRate?.score ?? 0,
        currentEpisode: self.userRate?.currentEpisode ?? 0,
        status: .planned,
        comment: ""
      )
    )

    do {
      self.userRate = try await self.scraperClient.sendAPIRequest(request)
    }
    catch {
      print("\(error.localizedDescription)")
    }
  }

  private func getUserRate(showId: Int) async {
    do {
      self.userRate = try await self.scraperClient.sendAPIRequest(
        ScraperAPI.Request.GetUserRate(showId: showId, fullCheck: true)
      )
    }
    catch {
      print("\(error.localizedDescription)")
    }
  }
}

struct ShowView: View {
  var showId: Int

  @State private var viewModel: ShowViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              showId: self.showId
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
  let show: ShowFull
  var viewModel: ShowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
      HeadingSectionWithBackground(imageUrl: self.show.posterUrl) {
        ShowKeyDetailsSection(show: self.show, viewModel: self.viewModel)
          .padding(.bottom, SPACING_BETWEEN_SECTIONS)
      }

      if !self.show.studios.isEmpty || !self.show.descriptions.isEmpty {
        ShowStudiosAndDescriptions(studios: self.show.studios, descriptions: self.show.descriptions)
      }

      if !self.show.screenshots.isEmpty {
        Screenshots(screenshots: self.show.screenshots)
      }
    }
  }
}

private struct ShowKeyDetailsSection: View {
  let show: ShowFull
  var viewModel: ShowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
      HStack(alignment: .top, spacing: SPACING_BETWEEN_SECTIONS) {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
          ShowPrimaryAndSecondaryTitles(title: self.show.title)

          ShowActionButtons(show: self.show, viewModel: self.viewModel)

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
  let title: ShowFull.Title

  var body: some View {
    VStack {
      Group {
        if self.title.translated.japaneseRomaji == nil || self.title.translated.russian == nil {
          Text(self.title.full)
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
  let show: ShowFull
  var viewModel: ShowViewModel
  @State var showEdit = false
  private let SPACING_BETWEEN_BUTTONS: CGFloat = 40

  var isInMyList: Bool {
    self.viewModel.showRateStatus != UserRateStatus.deleted
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: self.SPACING_BETWEEN_BUTTONS) {
        NavigationLink(
          destination: EpisodeListView(showId: self.show.id)
        ) {
          Label(
            "Смотреть",
            systemImage: self.show.episodePreviews.isEmpty ? "play.slash.fill" : "play.fill"
          )
        }
        .buttonStyle(.bordered)
        .disabled(self.show.episodePreviews.isEmpty)

        if self.viewModel.statusReady {
          Button(action: {
            if self.isInMyList {
              self.showEdit = true
            }
            else {
              Task {
                await self.viewModel.addToList()
              }
            }
          }) {
            if self.isInMyList {
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
        if !self.show.episodePreviews.isEmpty && self.show.isOngoing,
          let episodeReleaseSchedule = guessEpisodeReleaseWeekdayAndTime(in: show.episodePreviews)
        {
          Text(
            "Обычно новые серии выходят по \(episodeReleaseSchedule.0), примерно в \(episodeReleaseSchedule.1)."
          )
        }

        if self.show.episodePreviews.isEmpty {
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
      isPresented: self.$showEdit,
      content: {
        MyListEditView(
          show: .init(
            id: self.show.id,
            name: self.show.title.compose,
            totalEpisodes: self.show.numberOfEpisodes ?? nil
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
        viewModel: .init(fetchShows: self.getShowsBySeason()),
        title: self.airingSeason.getLocalizedTranslation(),
        description: nil,
        displaySeason: false
      )
    ) {
      ShowProperty(
        label: "Сезон",
        value: self.airingSeason.getLocalizedTranslation(),
        isInteractive: true
      )
    }
    .buttonStyle(.plain)
  }

  private func getShowsBySeason() -> (_ offset: Int, _ limit: Int) async throws -> [Show] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [Show] {
      try await self.client.getSeason(
        offset: offset,
        limit: limit,
        airingSeason: self.airingSeason
      )
    }

    return fetchFunction
  }
}

private struct GenresShowProperty: View {
  let showTitle: ShowFull.Title
  let genres: [ShowFull.Genre]

  var body: some View {
    NavigationLink(
      destination: ShowGenreListView(
        showTitle: self.showTitle,
        genres: self.genres
      )
    ) {
      ShowProperty(
        label: "Жанры",
        value:
          self.genres
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
      value: self.formatString(),
      isInteractive: false
    )
  }

  private func formatString() -> String {
    let latestEpisodeNumber = self.getLatestEpisodeNumber()

    if self.isOngoing {
      return "Вышло \(latestEpisodeNumber.formatted()) из \(totalEpisodes?.formatted() ?? "???")"
    }

    if let totalEpisodes {
      return totalEpisodes.formatted()
    }

    return "???"
  }

  private func getLatestEpisodeNumber() -> Float {
    let filteredAndSortedEpisodes =
      self.episodePreviews
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

private struct ShowStudiosAndDescriptions: View {
  let studios: [ShowFull.Studio]
  let descriptions: [ShowFull.Description]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top) {
        if !self.studios.isEmpty {
          VStack(alignment: .leading) {
            Section(
              header: Text(self.studios.count == 1 ? "Студия" : "Студии")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            ) {
              LazyHStack(alignment: .top) {
                ForEach(self.studios) { studio in
                  StudioCard(
                    title: studio.name,
                    cover: studio.image,
                    id: studio.id
                  )
                  .frame(width: 300, height: 300)
                }
              }
            }
          }
        }

        if !self.descriptions.isEmpty {
          VStack(alignment: .leading) {
            Section(
              header: Text("Описание")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            ) {
              LazyHStack(alignment: .top) {
                ForEach(self.descriptions, id: \.self) { description in
                  ShowDescriptionCard(
                    title: description.source,
                    text: description.text
                  )
                  .frame(width: 600, height: 300)
                }
              }
            }
          }
        }
      }
    }
    .scrollClipDisabled()
  }
}

private struct StudioCard: View {
  public let title: String
  public let cover: URL?
  public let id: Int

  var body: some View {
    Button(action: {}) {
      VStack(alignment: .leading, spacing: 16) {
        Group {
          if let cover {
            AsyncImage(
              url: cover,
              transaction: .init(animation: .easeInOut(duration: 0.5))
            ) { phase in
              switch phase {
              case .empty:
                Color.clear

              case let .success(image):
                image
                  .resizable()
                  .scaledToFit()

              case .failure:
                Color.clear

              @unknown default:
                Color.clear
              }
            }
          }
          else {
            Color.clear
          }
        }
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity
        )

        Text(self.title)
          .lineLimit(1)
          .truncationMode(.tail)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .padding(24)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .leading
      )
    }
    .buttonStyle(.card)
  }
}

private struct ShowDescriptionCard: View {
  public let title: String
  public let text: String

  @State private var isSheetPresented = false

  var body: some View {
    Button {
      self.isSheetPresented.toggle()
    } label: {
      VStack(alignment: .leading, spacing: 16) {
        Group {
          Text(self.title)
            .lineLimit(1)
            .truncationMode(.tail)
            .font(.body)
            .fontWeight(.bold)

          Text(self.text)
            .lineLimit(6)
            .truncationMode(.tail)
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(24)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
      )
    }
    .sheet(isPresented: self.$isSheetPresented) {
      ShowDescriptionCardSheet(title: self.title, text: self.text)
    }
    .buttonStyle(.card)
  }
}

private struct ShowDescriptionCardSheet: View {
  let title: String
  let text: String

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView([.vertical]) {
        VStack(spacing: 16) {
          Group {
            ForEach(self.text.split(separator: "\n\n"), id: \.self) { paragraph in
              Text(paragraph)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .focusable()
        }
        .frame(maxWidth: 1000, alignment: .center)
      }
    }
  }
}

private struct ImagePlaceholder: View {
  var body: some View {
    Image(systemName: "photo")
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

private struct Screenshots: View {
  private static let HEIGHT: CGFloat = 300

  let screenshots: [URL]

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text("Скриншоты")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.screenshots, id: \.self) { screenshot in
              Screenshot(url: screenshot)
                .frame(width: 16 / 9 * Self.HEIGHT, height: Self.HEIGHT)
            }
          }
        }
        .scrollClipDisabled()
      }
    }
  }
}

private struct Screenshot: View {
  let url: URL

  var body: some View {
    Button(action: {}) {
      AsyncImage(
        url: self.url,
        transaction: .init(animation: .easeInOut(duration: 0.5))
      ) { phase in
        switch phase {
        case .empty:
          Color.clear

        case let .success(image):
          image
            .resizable()
            .scaledToFit()

        case .failure:
          Color.clear

        @unknown default:
          Color.clear
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .leading
      )
    }
    .buttonStyle(.borderless)
  }
}

#Preview {
  NavigationStack {
    ShowView(showId: 8762)
  }
}

import ScraperAPI
import SwiftData
import SwiftUI

typealias UserRateStatus = ScraperAPI.Types.UserRateStatus
extension ScraperAPI.Types.UserRateStatus {
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
  }
}

private let SPACING_BETWEEN_SECTIONS: CGFloat = 50

private struct ShowDetails: View {
  let show: ShowFull
  var viewModel: ShowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
      HeadingSectionWithBackground(imageUrl: self.show.posterUrl) {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
          ShowKeyDetailsSection(show: self.show, viewModel: self.viewModel)

          if !self.show.studios.isEmpty || !self.show.descriptions.isEmpty {
            ShowStudiosAndDescriptions(studios: self.show.studios, descriptions: self.show.descriptions)
          }
        }
        .padding(.bottom, SPACING_BETWEEN_SECTIONS)
      }

      if !self.show.screenshots.isEmpty {
        ScreenshotsSection(screenshots: self.show.screenshots)
      }

      if !self.show.moments.isEmpty {
        MomentsSection(moments: self.show.moments)
      }

      if !self.show.characters.isEmpty {
        CharactersSection(characters: self.show.characters)
      }

      if !self.show.staffMembers.isEmpty {
        StaffMembersSection(staffMembers: self.show.staffMembers)
      }

      if !self.show.relatedShows.isEmpty {
        RelatedShowsSection(relatedShowsGroups: self.show.relatedShows)
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
                ? "★ \(self.show.score!.formatted(.number.precision(.fractionLength(2))))" : "???"
            )

            ShowProperty(
              label: "Тип",
              value: self.show.typeTitle
            )

            EpisodesShowProperty(
              totalEpisodes: self.show.numberOfEpisodes,
              latestAiredEpisodeNumber: self.show.latestAiredEpisodeNumber,
              isOngoing: self.show.isOngoing
            )

            if let airingSeason = self.show.airingSeason {
              SeasonShowProperty(airingSeason: airingSeason)
            }
            else {
              ShowProperty(
                label: "Сезон",
                value: "???"
              )
            }

            if !self.show.genres.isEmpty {
              GenresShowProperty(genres: self.show.genres)
            }
          }
        }

        if let posterUrl = self.show.posterUrl {
          Button(action: {}) {
            GeometryReader { geometry in
              AsyncImage(
                url: posterUrl,
                transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION)),
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
  @State private var showEdit = false
  private let SPACING_BETWEEN_BUTTONS: CGFloat = 40

  var isInMyList: Bool {
    self.viewModel.showRateStatus != UserRateStatus.deleted
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: self.SPACING_BETWEEN_BUTTONS) {
        if self.show.hasEpisodes {
          NavigationLink(
            destination: EpisodeListView(showId: self.show.id, nextEpisodeReleasesAt: self.show.nextEpisodeReleasesAt)
          ) {
            Label(
              "Смотреть",
              systemImage: "play.fill"
            )
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
          }
          .buttonStyle(.card)
        }

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
          Group {
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
          .font(.headline)
          .fontWeight(.semibold)
          .padding(.vertical, 20)
          .padding(.horizontal, 40)
        }
        .buttonStyle(.card)
      }
      .focusSection()

      Group {
        if let nextEpisodeReleasesAt = self.show.nextEpisodeReleasesAt {
          Text(
            "Следующая серия: \(formatRelativeDateWithWeekdayNameAndDateAndTime(nextEpisodeReleasesAt).lowercased())."
          )
        }
        else if !self.show.hasEpisodes {
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
        value: self.airingSeason.getLocalizedTranslation()
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
  let genres: [ShowFull.Genre]

  var body: some View {
    NavigationLink(
      destination: ShowGenreListView(
        genres: self.genres
      )
    ) {
      ShowProperty(
        label: "Жанры",
        value:
          self.genres
          .map { genre in genre.title }
          .formatted(.list(type: .and, width: .narrow))
      )
    }
    .buttonStyle(.plain)
  }
}

private struct EpisodesShowProperty: View {
  let totalEpisodes: Int?
  let latestAiredEpisodeNumber: Int?
  let isOngoing: Bool

  var body: some View {
    ShowProperty(
      label: "Количество эпизодов",
      value: self.formatString()
    )
  }

  private func formatString() -> String {
    if let latestAiredEpisodeNumber, self.isOngoing {
      return
        "Вышло \(latestAiredEpisodeNumber.formatted()) из \(totalEpisodes?.formatted() ?? EpisodeService.formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(latestAiredEpisodeNumber))"
    }

    if let totalEpisodes {
      return totalEpisodes.formatted()
    }

    return "???"
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
                    cover: studio.image
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
  let title: String
  let cover: URL?

  var body: some View {
    Button(action: {}) {
      VStack(alignment: .leading, spacing: 16) {
        AsyncImage(
          url: self.cover,
          transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
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
  let title: String
  let text: String

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
      ShowDescriptionCardSheet(text: self.text)
    }
    .buttonStyle(.card)
  }
}

private struct ShowDescriptionCardSheet: View {
  let text: String

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

private struct ScreenshotsSection: View {
  private static let SPACING: CGFloat = 64

  @State private var selectedScreenshot: URL? = nil
  @State private var showSheet: Bool = false

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
          LazyHStack(alignment: .top, spacing: Self.SPACING) {
            ForEach(self.screenshots, id: \.self) { screenshot in
              Button(action: {
                self.selectedScreenshot = screenshot
                self.showSheet = true
              }) {
                AsyncImage(
                  url: screenshot,
                  transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
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
                  maxHeight: .infinity
                )
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(Color.black)
                .hoverEffect(.highlight)
              }
              .buttonStyle(.borderless)
              .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: Self.SPACING)
            }
          }
        }
        .scrollClipDisabled()
        .sheet(isPresented: self.$showSheet) {
          NavigationStack {
            TabView(selection: self.$selectedScreenshot) {
              ForEach(self.screenshots, id: \.self) { screenshot in
                AsyncImage(
                  url: screenshot,
                  transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
                ) { phase in
                  switch phase {
                  case .empty:
                    ProgressView()

                  case let .success(image):
                    image
                      .resizable()
                      .scaledToFit()

                  case .failure:
                    Image(systemName: "photo.badge.exclamationmark")
                      .font(.title)
                      .foregroundColor(.secondary)

                  @unknown default:
                    Color.clear
                  }
                }
                .focusable()
                .frame(
                  maxWidth: .infinity,
                  maxHeight: .infinity
                )
                .ignoresSafeArea()
                .tag(screenshot)
              }
            }
            .tabViewStyle(.page)
          }
        }
      }
    }
  }
}

private struct CharactersSection: View {
  private static let SPACING: CGFloat = 64

  let characters: [Character]

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text("Персонажи")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: Self.SPACING) {
            ForEach(self.characters) { character in
              CharacterCard(character: character)
                .containerRelativeFrame(.horizontal, count: 6, span: 1, spacing: Self.SPACING)
            }
          }
        }
        .scrollClipDisabled()
      }
    }
  }
}

private struct StaffMembersSection: View {
  private static let SPACING: CGFloat = 64

  let staffMembers: [StaffMember]

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text("Авторы")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: Self.SPACING) {
            ForEach(self.staffMembers) { staffMember in
              StaffMemberCard(staffMember: staffMember)
                .containerRelativeFrame(.horizontal, count: 6, span: 1, spacing: Self.SPACING)
            }
          }
        }
        .scrollClipDisabled()
      }
    }
  }
}

private struct MomentsSection: View {
  private static let SPACING: CGFloat = 64

  let moments: [Moment]

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text("Моменты")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: Self.SPACING) {
            ForEach(self.moments) { moment in
              MomentCard(moment: moment)
                .containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: Self.SPACING)
            }
          }
        }
        .scrollClipDisabled()
      }
    }
  }
}

private struct RelatedShowsSection: View {
  let relatedShowsGroups: [GroupedRelatedShows]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top) {
        ForEach(self.relatedShowsGroups, id: \.relationTitle) { relatedShowGroup in
          VStack(alignment: .leading) {
            Section(
              header: Text(relatedShowGroup.relationTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            ) {
              LazyHStack(alignment: .top) {
                ForEach(relatedShowGroup.relatedShows, id: \.myAnimeListId) { relatedShow in
                  RelatedShowCard(relatedShow: relatedShow)
                    .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 64)
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

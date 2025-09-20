import OrderedCollections
import SwiftData
import SwiftUI

@Observable
private class ShowViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(
      (
        show: ShowDetails,
        moments: OrderedSet<Moment>,
        screenshots: OrderedSet<URL>,
        characters: OrderedSet<CharacterInfo>,
        staffMembers: OrderedSet<StaffMember>,
        relatedShows: OrderedSet<GroupedRelatedShows>
      )
    )
  }

  private var _state: State = .idle
  private let showService: ShowService
  private var showId: Int = 0

  private(set) var state: State {
    get {
      self._state
    }
    set {
      withAnimation {
        self._state = newValue
      }
    }
  }

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(showId: Int) async {
    self.state = .loading

    self.showId = showId

    do {
      let show = try await showService.getShowDetails(
        showId: showId
      )

      self.state = .loaded(show)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct ShowView: View {
  @State private var viewModel: ShowViewModel = .init()

  private let showId: Int
  private let onOpened: (() -> Void)?

  init(
    showId: Int,
    onOpened: (() -> Void)? = nil
  ) {
    self.showId = showId
    self.onOpened = onOpened
  }

  var body: some View {
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
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad(
              showId: self.showId
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case let .loaded((show, moments, screenshots, characters, staffMembers, relatedShows)):
      ScrollView(.vertical) {
        ShowDetailsView(
          show: show,
          moments: moments,
          screenshots: screenshots,
          characters: characters,
          staffMembers: staffMembers,
          relatedShows: relatedShows,
        )
      }
      .onAppear {
        guard let onOpened = self.onOpened else {
          return
        }

        onOpened()
      }
    }
  }
}

private let SPACING_BETWEEN_SECTIONS: CGFloat = 50

private struct ShowDetailsView: View {
  let show: ShowDetails
  let moments: OrderedSet<Moment>
  let screenshots: OrderedSet<URL>
  let characters: OrderedSet<CharacterInfo>
  let staffMembers: OrderedSet<StaffMember>
  let relatedShows: OrderedSet<GroupedRelatedShows>

  var body: some View {
    VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
      HeadingSectionWithBackground(imageUrl: self.show.posterUrl) {
        VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
          ShowKeyDetailsSection(show: self.show)

          if !self.show.studios.isEmpty || !self.show.descriptions.isEmpty {
            ShowStudiosAndDescriptions(studios: self.show.studios, descriptions: self.show.descriptions)
          }

          if !self.show.genres.isEmpty {
            ShowGenres(genres: self.show.genres)
          }
        }
        .padding(.bottom, SPACING_BETWEEN_SECTIONS)
      }

      if !self.screenshots.isEmpty {
        ScreenshotsSection(screenshots: self.screenshots)
      }

      if !self.moments.isEmpty {
        ShowMomentsSection(showId: self.show.id, preloadedMoments: self.moments)
      }

      if !self.characters.isEmpty {
        CharactersSection(characters: self.characters)
      }

      if !self.staffMembers.isEmpty {
        StaffMembersSection(staffMembers: self.staffMembers)
      }

      if !self.relatedShows.isEmpty {
        RelatedShowsSection(relatedShowsGroups: self.relatedShows)
      }
    }
  }
}

private struct ShowKeyDetailsSection: View {
  let show: ShowDetails

  @State private var displayShowCoversSheet: Bool = false

  var body: some View {
    HStack(alignment: .top, spacing: SPACING_BETWEEN_SECTIONS) {
      VStack(alignment: .leading, spacing: SPACING_BETWEEN_SECTIONS) {
        ShowPrimaryAndSecondaryTitles(title: self.show.title)

        ShowActionButtons(show: self.show)

        Grid(alignment: .topLeading, horizontalSpacing: 64, verticalSpacing: 32) {
          GridRow {
            RatingProperty(
              score: self.show.score,
              scoredBy: self.show.scoredBy,
              rank: self.show.rank
            )

            if self.show.popularity != nil || self.show.members != nil {
              PopularityProperty(
                popularity: self.show.popularity,
                members: self.show.members
              )
            }
          }

          GridRow {
            ShowProperty(
              label: "Тип",
              value: self.show.kind?.title ?? "???"
            )

            EpisodesShowProperty(
              totalEpisodes: self.show.numberOfEpisodes,
              latestAiredEpisodeNumber: self.show.latestAiredEpisodeNumber,
              isOngoing: self.show.isOngoing
            )
          }

          GridRow {
            ShowProperty(
              label: "Источник",
              value: self.show.source ?? "???"
            )
          }

          GridRow {
            if let airingSeason = self.show.airingSeason {
              SeasonShowProperty(airingSeason: airingSeason)
            }
            else {
              ShowProperty(
                label: "Сезон",
                value: "???"
              )
            }
          }
        }
      }
      .frame(maxHeight: .infinity, alignment: .topLeading)

      if let coverUrl = self.show.posterUrl {
        Button(action: {
          self.displayShowCoversSheet = true
        }) {
          AsyncImage(
            url: coverUrl,
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
        }
        .buttonStyle(.borderless)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .aspectRatio(425 / 600, contentMode: .fit)
        .frame(width: 500)
        .fullScreenCover(isPresented: self.$displayShowCoversSheet) {
          CoverGallerySheet(myAnimeListId: self.show.myAnimeListId)
            .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .focusSection()
  }
}

private struct ShowPrimaryAndSecondaryTitles: View {
  let title: ShowName

  var body: some View {
    VStack {
      Group {
        switch self.title {
        case let .parsed(romaji, russian):
          Text(romaji)
            .font(.title2)

          if let russian {
            Text(russian)
              .font(.title3)
              .foregroundStyle(.secondary)
          }
        case let .unparsed(fullName):
          Text(fullName)
            .font(.title2)
        }
      }
      .lineLimit(2)
      .truncationMode(.tail)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct ShowActionButtons: View {
  let show: ShowDetails

  private let SPACING_BETWEEN_BUTTONS: CGFloat = 40

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: self.SPACING_BETWEEN_BUTTONS) {
        if self.show.hasEpisodes {
          NavigationLink(
            destination: EpisodeListView(
              showId: self.show.id,
              myAnimeListId: self.show.myAnimeListId,
              totalEpisodes: self.show.numberOfEpisodes,
              nextEpisodeReleasesAt: self.show.nextEpisodeReleasesAt
            )
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

        ShowInMyListStatusButton(
          showId: self.show.id,
          showName: self.show.title,
          episodesTotal: self.show.numberOfEpisodes
        )
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
  let showService: ShowService

  init(
    airingSeason: AiringSeason,
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.airingSeason = airingSeason
    self.showService = showService
  }

  var body: some View {
    NavigationLink(
      destination: FilteredShowsView(
        title: self.airingSeason.getLocalizedTranslation(),
        displaySeason: false,
        fetchShows: self.getShowsBySeason()
      )
    ) {
      ShowProperty(
        label: "Сезон",
        value: self.airingSeason.getLocalizedTranslation()
      )
    }
    .buttonStyle(.plain)
  }

  private func getShowsBySeason() -> (_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
    func fetchFunction(_ offset: Int, _ limit: Int) async throws -> [ShowPreview] {
      try await self.showService.getSeason(
        offset: offset,
        limit: limit,
        airingSeason: self.airingSeason
      )
    }

    return fetchFunction
  }
}

private struct RatingProperty: View {
  let score: Float?
  let scoredBy: Int?
  let rank: Int?

  var body: some View {
    ShowProperty(
      label: self.formatLabel(),
      value: self.formatPropertyValue()
    )
  }

  private func formatLabel() -> String {
    if let rank = self.rank {
      return "Топ \(rank.formatted(ShortLargeNumberFormatter())) по рейтингу"
    }

    return "Рейтинг"
  }

  private func formatPropertyValue() -> String {
    var components: [String] = []

    if let score = self.score {
      components.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let scoredBy = self.scoredBy {
      components.append("\(scoredBy.formatted(ShortLargeNumberFormatter())) оценок")
    }

    if components.isEmpty {
      return "???"
    }

    return components.joined(separator: " • ")
  }
}

private struct PopularityProperty: View {
  let popularity: Int?
  let members: Int?

  var body: some View {
    ShowProperty(
      label: self.formatLabel(),
      value: self.formatPropertyValue()
    )
  }

  private func formatLabel() -> String {
    if let popularity = self.popularity {
      return "Топ \(popularity.formatted(ShortLargeNumberFormatter())) по популярности"
    }

    return "Популярность"
  }

  private func formatPropertyValue() -> String {
    if let members = self.members {
      return "\(members.formatted(ShortLargeNumberFormatter())) зрителей"
    }

    return "??? зрителей"
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
    if let latestAiredEpisodeNumber = self.latestAiredEpisodeNumber, self.isOngoing {
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
  let studios: OrderedSet<Studio>
  let descriptions: [ShowDetails.Description]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top) {
        if !self.studios.isEmpty {
          SectionWithCards(title: self.studios.count == 1 ? "Студия" : "Студии") {
            LazyHStack(alignment: .top) {
              ForEach(self.studios) { studio in
                StudioCard(
                  id: studio.id,
                  title: studio.name,
                  cover: studio.image
                )
                .frame(width: 300, height: 300)
              }
            }
          }
        }

        if !self.descriptions.isEmpty {
          SectionWithCards(title: "Описание") {
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
    .focusSection()
    .scrollClipDisabled()
  }
}

private struct ShowGenres: View {
  let genres: OrderedSet<Genre>

  var body: some View {
    SectionWithCards(title: "Жанры") {
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 32) {
          ForEach(self.genres) { genre in
            GenreCard(id: genre.id, title: genre.title)
          }
        }
      }
      .scrollClipDisabled()
    }
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
    .fullScreenCover(isPresented: self.$isSheetPresented) {
      ShowDescriptionCardSheet(text: self.text)
        .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
    }
    .buttonStyle(.card)
  }
}

private struct ShowDescriptionCardSheet: View {
  let text: String

  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
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

  let screenshots: OrderedSet<URL>

  var body: some View {
    SectionWithCards(title: "Скриншоты") {
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
    }
    .fullScreenCover(isPresented: self.$showSheet) {
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
      .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
    }
  }
}

private struct CharactersSection: View {
  private static let SPACING: CGFloat = 64

  let characters: OrderedSet<CharacterInfo>

  var body: some View {
    SectionWithCards(title: "Персонажи") {
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

private struct StaffMembersSection: View {
  private static let SPACING: CGFloat = 64

  let staffMembers: OrderedSet<StaffMember>

  var body: some View {
    SectionWithCards(title: "Авторы") {
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

private struct RelatedShowsSection: View {
  let relatedShowsGroups: OrderedSet<GroupedRelatedShows>

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
        ForEach(self.relatedShowsGroups) { relatedShowGroup in
          SectionWithCards(title: relatedShowGroup.relationKind.title) {
            LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
              ForEach(relatedShowGroup.relatedShows) { relatedShow in
                ShowCardMyAnimeList(relatedShow: relatedShow)
                  .containerRelativeFrame(
                    .horizontal,
                    count: ShowCard.RECOMMENDED_COUNT_PER_ROW,
                    span: 1,
                    spacing: ShowCard.RECOMMENDED_SPACING
                  )
              }
            }
          }
        }
      }
    }
    .focusSection()
    .scrollClipDisabled()
  }
}

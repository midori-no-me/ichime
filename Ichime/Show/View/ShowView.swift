import OrderedCollections
import SwiftData
import SwiftUI

@Observable @MainActor
private final class ShowViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(ShowDetails)
  }

  private(set) var state: State = .idle

  private let showService: ShowService
  private let showId: Int

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    showId: Int
  ) {
    self.showService = showService
    self.showId = showId
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let show = try await showService.getShowDetails(
        showId: self.showId
      )

      self.updateState(.loaded(show))
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.default.speed(0.5)) {
      self.state = state
    }
  }
}

struct ShowView: View {
  @State private var viewModel: ShowViewModel
  @State private var displayShowCoversSheet: Bool = false

  private let onOpened: (() -> Void)?

  init(
    showId: Int,
    onOpened: (() -> Void)? = nil
  ) {
    self.onOpened = onOpened
    self.viewModel = .init(showId: showId)
  }

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      ProgressView()
        .focusable()
        .centeredContentFix()
        .onAppear {
          Task {
            await self.viewModel.performInitialLoading()
          }
        }

    case .loading:
      ProgressView()
        .focusable()
        .centeredContentFix()

    case let .loadingFailed(error):
      if case GetShowByIdError.notFoundByMyAnimeListId = error {
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "exclamationmark.triangle")
        } description: {
          Text("Возможно, этого тайтла не существует.\nЛибо он был удален из базы данных Anime 365.")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoading()
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()
      }
      else {
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoading()
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()
      }

    case let .loaded(show):
      GeometryReader { proxy in
        ScrollView(.vertical) {
          VStack(spacing: 64) {
            // MARK: Top full screen section

            ZStack {
              // MARK: Top full screen section - Background image
              AsyncImage(
                url: show.posterUrl,
                transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION)),
                content: { phase in
                  switch phase {
                  case .empty:
                    Color.clear

                  case let .success(image):
                    image
                      .resizable()

                  case .failure:
                    Color.clear

                  @unknown default:
                    Color.clear
                  }
                }
              )
              .opacity(0.5)
              .blur(radius: 100, opaque: false)

              // MARK: Top full screen section - Content
              HStack(alignment: .top, spacing: 64) {
                VStack(alignment: .leading, spacing: 32) {
                  VStack(alignment: .leading, spacing: 8) {
                    Group {
                      switch show.title {
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

                  HStack(spacing: 32) {
                    NavigationLink(
                      destination: EpisodeListView(
                        showId: show.id,
                        myAnimeListId: show.myAnimeListId,
                        totalEpisodes: show.numberOfEpisodes,
                        nextEpisodeReleasesAt: show.nextEpisodeReleasesAt
                      )
                    ) {
                      Label("Смотреть", systemImage: "play.fill")
                        .labelIconToTitleSpacing(16)
                        .font(.headline)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .controlSize(.extraLarge)

                    ShowInMyListStatusButton(
                      showId: show.id,
                      showName: show.title,
                      episodesTotal: show.numberOfEpisodes
                    )
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .controlSize(.extraLarge)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .focusSection()

                  if let episodeStatus = Self.formatCurrentEpisodeStatus(show: show) {
                    Text(episodeStatus)
                      .foregroundStyle(.secondary)
                      .frame(maxWidth: .infinity, alignment: .leading)
                      .font(.caption)
                  }

                  VStack(alignment: .leading, spacing: 16) {
                    if let chips = Optional(Self.prepareChips(show: show)), chips.count > 0 {
                      HStack(spacing: Chip.RECOMMENDED_SPACING) {
                        ForEach(chips, id: \.self) { chip in
                          Chip.outlined(label: chip)
                        }
                      }
                    }

                    if let description = show.descriptions.first {
                      Text(description.singleLineText)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }

                    if show.genres.count > 0 {
                      Text((show.genres.map(\.title)).joined(separator: " • "))
                        .font(.caption)
                    }
                  }
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                Button(action: {
                  self.displayShowCoversSheet = true
                }) {
                  AsyncImage(
                    url: show.posterUrl,
                    transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION)),
                    content: { phase in
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
                  )
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .aspectRatio(ShowCard.RECOMMENDED_ASPECT_RATIO, contentMode: .fit)
                .fullScreenCover(isPresented: self.$displayShowCoversSheet) {
                  CoverGallerySheet(myAnimeListId: show.myAnimeListId)
                    .background(.thickMaterial)
                }
              }
              .focusSection()
              .padding(.top, proxy.safeAreaInsets.top)
              .padding(.bottom, proxy.safeAreaInsets.bottom)
              .padding(.leading, proxy.safeAreaInsets.leading)
              .padding(.trailing, proxy.safeAreaInsets.trailing)
            }
            .ignoresSafeArea(edges: .horizontal)
            .frame(
              height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
            )

            // MARK: Lazy-loadable sections
            ScreenshotCardsSection(myAnimeListId: show.myAnimeListId)
            ShowMomentsSection(showId: show.id)
            CharacterCardsSection(myAnimeListId: show.myAnimeListId)
            StaffMemberCardsSection(myAnimeListId: show.myAnimeListId)
            RelatedShowsSection(myAnimeListId: show.myAnimeListId)

            if !show.studios.isEmpty || !show.descriptions.isEmpty {
              ShowStudiosAndDescriptionsSection(studios: show.studios, descriptions: show.descriptions)
            }
          }
          .padding(.bottom, proxy.safeAreaInsets.bottom)
        }
        .ignoresSafeArea(edges: .vertical)
      }
      .onAppear {
        guard let onOpened = self.onOpened else {
          return
        }

        onOpened()
      }
    }
  }

  private static func prepareChips(show: ShowDetails) -> [String] {
    var items: [String] = []

    if let score = show.score {
      items.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let ageRating = show.ageRating {
      items.append(ageRating.shortLabel)
    }

    if let season = show.airingSeason?.getLocalizedTranslation() {
      items.append(season)
    }

    if let kind = show.kind {
      items.append(kind.title)
    }

    if let episodes = show.numberOfEpisodes {
      items.append("\(episodes.formatted()) эп.")
    }

    if let studio = Self.formatStudioLabel(show: show) {
      items.append(studio)
    }

    return items
  }

  private static func formatStudioLabel(show: ShowDetails) -> String? {
    if show.studios.count == 1 {
      return show.studios.first?.name
    }

    if show.studios.count > 1 {
      return "\(show.studios[0].name) +\(show.studios.count - 1)"
    }

    return nil
  }

  private static func formatCurrentEpisodeStatus(show: ShowDetails) -> String? {
    if let nextEpisodeReleasesAt = show.nextEpisodeReleasesAt {
      if let latestAiredEpisodeNumber = show.latestAiredEpisodeNumber {
        return
          "Вышло \(latestAiredEpisodeNumber.formatted()) эп., следующий: \(formatRelativeDateWithWeekdayNameAndDateAndTime(nextEpisodeReleasesAt).lowercased())."
      }

      return "Следующий эпизод: \(formatRelativeDateWithWeekdayNameAndDateAndTime(nextEpisodeReleasesAt).lowercased())."
    }

    if !show.hasEpisodes {
      return "У этого тайтла пока что нет загруженных серий."
    }

    return nil
  }
}

private struct ShowStudiosAndDescriptionsSection: View {
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
                  text: description.text,
                  textPreview: description.singleLineText,
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

private struct ShowDescriptionCard: View {
  let title: String
  let text: String
  let textPreview: String

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

          Text(self.textPreview)
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
        .background(.thickMaterial)
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

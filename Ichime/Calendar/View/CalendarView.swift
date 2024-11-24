import SwiftUI

class CalendarViewModel: ObservableObject {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([GroupedShowsFromCalendar])
  }

  @Published private(set) var state = State.idle

  private var shows: [GroupedShowsFromCalendar] = []

  private let schedule: ShowReleaseSchedule

  init(
    schedule: ShowReleaseSchedule
  ) {
    self.schedule = schedule
  }

  @MainActor
  func updateState(_ newState: State) {
    state = newState
  }

  func performInitialLoad() async {
    await updateState(.loading)

    do {
      let shows = try await schedule.getSchedule()

      if shows.isEmpty {
        await updateState(.loadedButEmpty)
      } else {
        self.shows = shows
        await updateState(.loaded(self.shows))
      }
    } catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performPullToRefresh() async {
    do {
      let shows = try await schedule.getSchedule()

      if shows.isEmpty {
        await updateState(.loadedButEmpty)
      } else {
        self.shows = shows
        await updateState(.loaded(self.shows))
      }
    } catch {
      await updateState(.loadingFailed(error))
    }
  }
}


struct CalendarView: View {
  @StateObject public var viewModel: CalendarViewModel = CalendarViewModel(schedule: ShowReleaseSchedule())

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
#if os(tvOS)
          .focusable()
#endif

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
#if !os(tvOS)
        .textSelection(.enabled)
#endif

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Возможно, это баг")
        }

      case let .loaded(groupsOfShows):
        if UIDevice.current.userInterfaceIdiom == .phone {
          List {
            ForEach(groupsOfShows, id: \.self) { groupOfShows in
              Section {
                ForEach(groupOfShows.shows) { show in
                  ShowFromCalendarCard(show: show)
                }
              } header: {
                Text(formatRelativeDateDay(groupOfShows.date))
              }
            }
          }
          .listStyle(.plain)
        } else {
          ScrollView([.vertical]) {
            VStack(alignment: .leading, spacing: 70) {
              ForEach(groupsOfShows, id: \.self) { groupOfShows in
                VStack(alignment: .leading, spacing: 50) {
                  SectionHeaderRaw(
                    title: formatRelativeDateDay(groupOfShows.date),
                    subtitle: nil
                  )

                  LazyVGrid(columns: [
                    GridItem(
                      .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
                      spacing: RawShowCard.RECOMMENDED_SPACING,
                      alignment: .topLeading
                    ),
                  ], spacing: RawShowCard.RECOMMENDED_SPACING) {
                    ForEach(groupOfShows.shows) { show in
                      ShowFromCalendarCard(show: show)
                    }
                  }
                }
              }
            }
            .horizontalScreenEdgePadding()
            .topEdgePaddingForMenu()
          }
        }
      }
    }
#if !os(tvOS)
    .navigationTitle("Календарь")
    .navigationBarTitleDisplayMode(.large)
#endif
    .refreshable {
      await self.viewModel.performPullToRefresh()
    }
#if os(tvOS)
    .toolbar(.hidden, for: .tabBar)
#endif
  }
}

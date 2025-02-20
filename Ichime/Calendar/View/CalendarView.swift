import SwiftUI

class CalendarViewModel: ObservableObject {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([GroupedShowsFromCalendar])
  }

  @Published private(set) var state: State = .idle

  private var shows: [GroupedShowsFromCalendar] = []

  private let schedule: ShowReleaseSchedule

  init(
    schedule: ShowReleaseSchedule
  ) {
    self.schedule = schedule
  }

  @MainActor
  func updateState(_ newState: State) {
    self.state = newState
  }

  func performInitialLoad() async {
    await self.updateState(.loading)

    do {
      let shows = try await schedule.getSchedule()

      if shows.isEmpty {
        await self.updateState(.loadedButEmpty)
      }
      else {
        self.shows = shows
        await self.updateState(.loaded(self.shows))
      }
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }
}

struct CalendarView: View {
  @StateObject private var viewModel: CalendarViewModel = CalendarViewModel(
    schedule: ShowReleaseSchedule(shikimoriApiClient: ApplicationDependency.container.resolve())
  )

  var body: some View {
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
        .centeredContentFix()

    case let .loadingFailed(error):
      ContentUnavailableView {
        Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
      } description: {
        Text(error.localizedDescription)
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad()
          }
        }) {
          Text("Обновить")
        }
      }

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Ничего не нашлось", systemImage: "list.bullet")
      } description: {
        Text("Возможно, это баг")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad()
          }
        }) {
          Text("Обновить")
        }
      }

    case let .loaded(groupsOfShows):
      ScrollView([.vertical]) {
        VStack(alignment: .leading, spacing: 70) {
          ForEach(groupsOfShows, id: \.self) { groupOfShows in
            VStack(alignment: .leading, spacing: 50) {
              SectionHeaderRaw(
                title: formatRelativeDateDay(groupOfShows.date),
                subtitle: nil
              )

              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
                ForEach(groupOfShows.shows) { show in
                  ShowFromCalendarCard(show: show)
                    .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
                }
              }
            }
          }
        }
      }
    }
  }
}

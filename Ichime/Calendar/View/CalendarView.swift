import SwiftUI

@Observable
private class CalendarViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([GroupedShowsFromCalendar])
  }

  private(set) var state: State = .idle

  private let schedule: ShowReleaseSchedule

  init(
    schedule: ShowReleaseSchedule = ApplicationDependency.container.resolve()
  ) {
    self.schedule = schedule
  }

  func performInitialLoad() async {
    self.state = .loading

    do {
      let shows = try await schedule.getSchedule()

      if shows.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(shows)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct CalendarView: View {
  @State private var viewModel: CalendarViewModel = .init()

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
      .centeredContentFix()

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
      .centeredContentFix()

    case let .loaded(scheduleDays):
      ScrollView([.vertical]) {
        VStack(alignment: .leading, spacing: 64) {
          ForEach(scheduleDays, id: \.date) { scheduleDay in
            SectionWithCards(title: formatRelativeDateWithWeekdayNameAndDate(scheduleDay.date)) {
              LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
                ForEach(scheduleDay.shows) { show in
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

import OrderedCollections
import SwiftUI

@Observable
private class CalendarViewModel {
  enum State {
    case idle
    case loading
    case loadedButEmpty
    case loaded(OrderedSet<ShowsFromCalendarGroupedByDate>)
  }

  private var _state: State = .idle
  private let schedule: ShowReleaseSchedule

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
    schedule: ShowReleaseSchedule = ApplicationDependency.container.resolve()
  ) {
    self.schedule = schedule
  }

  func performInitialLoad() async {
    self.state = .loading

    let shows = await schedule.getSchedule()

    if shows.isEmpty {
      self.state = .loadedButEmpty
    }
    else {
      self.state = .loaded(shows)
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
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 64) {
          ForEach(scheduleDays, id: \.date) { scheduleDay in
            SectionWithCards(title: formatRelativeDateWithWeekdayNameAndDate(scheduleDay.date)) {
              ScrollView(.horizontal) {
                LazyHStack(alignment: .top) {
                  ForEach(scheduleDay.shows) { show in
                    ShowFromCalendarWithExactReleaseDateCard(show: show)
                      .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
                      .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 64)
                  }
                }
              }
              .scrollClipDisabled()
            }
          }
        }
      }
    }
  }
}

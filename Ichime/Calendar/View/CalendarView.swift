import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class CalendarViewModel {
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
        LazyVStack(alignment: .leading, spacing: 64) {
          ForEach(scheduleDays) { scheduleDay in
            SectionWithCards(title: formatRelativeDateWithWeekdayNameAndDate(scheduleDay.date)) {
              ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
                  ForEach(scheduleDay.shows) { show in
                    ShowCardMyAnimeList(show: show)
                      .containerRelativeFrame(
                        .horizontal,
                        count: ShowCard.RECOMMENDED_COUNT_PER_ROW,
                        span: 1,
                        spacing: ShowCard.RECOMMENDED_SPACING
                      )
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

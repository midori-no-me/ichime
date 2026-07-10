import IchimeEpisode
import IchimeMyLists
import IchimeShow
import SwiftUI

@Observable @MainActor
private final class EditAnimeListEntrySheetViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(AnimeListEditableEntry)
  }

  private(set) var state: State = .idle

  private let animeListService: AnimeListService

  init(
    animeListService: AnimeListService = AppDependencies.live.animeListService
  ) {
    self.animeListService = animeListService
  }

  func performInitialLoad(
    showID: Int
  ) async {
    self.state = .loading

    do {
      let animeListEditableEntry = try await animeListService.getAnimeListEditableEntry(showID: showID)

      self.state = .loaded(animeListEditableEntry)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func save(
    showID: Int,
    status: AnimeListCategory,
    score: AnimeListScore,
    episodesWatched: Int
  ) async {
    try? await self.animeListService.editAnimeListEntry(
      showID: showID,
      status: status,
      score: score,
      episodesWatched: episodesWatched
    )
  }

  func delete(
    showID: Int
  ) async {
    try? await self.animeListService.deleteAnimeListEntry(showID: showID)
  }
}

struct EditAnimeListEntrySheet: View {
  @State private var viewModel: EditAnimeListEntrySheetViewModel = .init()

  @Environment(\.dismiss) private var dismissSheet

  let showID: Int
  let showName: ShowName
  let episodesTotal: Int?
  let onUpdate: () async -> Void

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(showID: self.showID)
          }
        }

      case .loading:
        ProgressView()
          .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(showID: self.showID)
            }
          }) {
            Text("Обновить")
          }
        }

      case let .loaded(animeListEditableEntry):
        EditAnimeListEntryForm(
          showID: self.showID,
          showName: self.showName,
          status: animeListEditableEntry.status.category ?? .planned,
          score: animeListEditableEntry.score,
          episodesWatched: animeListEditableEntry.episodesWatched,
          episodesTotal: self.episodesTotal,
          save: { showID, status, score, episodesWatched in
            await self.viewModel.save(
              showID: showID,
              status: status,
              score: score,
              episodesWatched: episodesWatched
            )

            await self.onUpdate()

            self.dismissSheet()
          },
          delete: { showID in
            await self.viewModel.delete(showID: showID)

            await self.onUpdate()

            self.dismissSheet()
          }
        )
      }
    }
    .navigationTitle(self.showName.getRomajiOrFullName())
  }
}

struct EditAnimeListEntryForm: View {
  @State private var showDeleteFromListConfirmationDialog = false

  @State private var status: AnimeListCategory
  @State private var score: AnimeListScore
  @State private var episodesWatched: Int

  private let showID: Int
  private let showName: ShowName

  private let episodesTotal: Int?

  private let save:
    (
      _ showID: Int,
      _ status: AnimeListCategory,
      _ score: AnimeListScore,
      _ episodesWatched: Int
    ) async -> Void

  private let delete:
    (
      _ showID: Int
    ) async -> Void

  init(
    showID: Int,
    showName: ShowName,
    status: AnimeListCategory,
    score: AnimeListScore,
    episodesWatched: Int,
    episodesTotal: Int?,
    save:
      @escaping (
        _ showID: Int,
        _ status: AnimeListCategory,
        _ score: AnimeListScore,
        _ episodesWatched: Int
      ) async -> Void,
    delete:
      @escaping (
        _ showID: Int
      ) async -> Void
  ) {
    self.showID = showID
    self.showName = showName
    self.status = status
    self.score = score
    self.episodesWatched = episodesWatched
    self.episodesTotal = episodesTotal
    self.save = save
    self.delete = delete
  }

  var body: some View {
    Form {
      Picker("Статус", selection: self.$status) {
        ForEach(AnimeListCategory.allCases) { category in
          Text(category.label)
        }
      }

      Picker("Оценка", selection: self.$score) {
        ForEach(AnimeListScore.allCases, id: \.self) { score in
          Text(score.label)
        }
      }

      Section {
        Button("+1 эпизод") {
          withAnimation {
            if let episodesTotal {
              self.episodesWatched = min(episodesTotal, self.episodesWatched + 1)
            }
            else {
              self.episodesWatched += 1
            }
          }
        }

        Button("-1 эпизод") {
          withAnimation {
            self.episodesWatched = max(0, self.episodesWatched - 1)
          }
        }
      } header: {
        Text("Просмотрено \(self.episodesWatched) эпизодов")
          .contentTransition(.numericText())

      } footer: {
        if let episodesTotal {
          Text("Всего эпизодов: \(episodesTotal.formatted(EpisodeNumberFormatter()))")
        }
      }

      Section {
        Button("Сохранить", role: .confirm) {
          Task {
            await self.save(
              self.showID,
              self.status,
              self.score,
              self.episodesWatched
            )
          }
        }
      }

      Section {
        Button("Удалить из списка", role: .destructive) {
          self.showDeleteFromListConfirmationDialog = true
        }
        .confirmationDialog(
          "Вы уверены?",
          isPresented: self.$showDeleteFromListConfirmationDialog,
          titleVisibility: .visible
        ) {
          Button("Да, удалить", role: .destructive) {
            Task {
              await self.delete(self.showID)
            }
          }
          Button("Отмена", role: .cancel) {
            self.showDeleteFromListConfirmationDialog = false
          }
        } message: {
          Text("Тайтл \(self.showName.getRomajiOrFullName()) будет удалён из вашего списка")
        }
      }
    }
  }
}

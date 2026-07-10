import IchimeShow
import SwiftUI

@Observable @MainActor
private final class CoverGallerySheetViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([URL])
  }

  // MARK: Properties

  private var _state: State = .idle
  private let showService: ShowService

  // MARK: Computed Properties

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

  // MARK: Lifecycle

  init(
    showService: ShowService = AppDependencies.live.showService
  ) {
    self.showService = showService
  }

  // MARK: Functions

  func performInitialLoad(myAnimeListID: Int) async {
    self.state = .loading

    do {
      let coverURLs = try await showService.getAllShowCovers(myAnimeListID)

      if coverURLs.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(coverURLs)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct CoverGallerySheet: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: CoverGallerySheetViewModel = .init()

  // MARK: Properties

  let myAnimeListID: Int

  // MARK: Content Properties

  var body: some View {
    NavigationStack {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              myAnimeListID: self.myAnimeListID
            )
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
              await self.viewModel.performInitialLoad(
                myAnimeListID: self.myAnimeListID
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("У этого тайтла нет обложек")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                myAnimeListID: self.myAnimeListID
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case let .loaded(coverURLs):
        TabView {
          ForEach(coverURLs, id: \.self) { coverURL in
            AsyncImage(
              url: coverURL,
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
          }
        }
        .tabViewStyle(.page)
      }
    }
  }
}

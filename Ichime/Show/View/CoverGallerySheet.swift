import SwiftUI

@Observable
private class CoverGallerySheetViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([URL])
  }

  private(set) var state: State = .idle

  private let showService: ShowService

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(myAnimeListId: Int) async {
    self.state = .loading

    do {
      let coverUrls = try await showService.getAllShowCovers(myAnimeListId)

      if coverUrls.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(coverUrls)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct CoverGallerySheet: View {
  let myAnimeListId: Int

  @State private var viewModel: CoverGallerySheetViewModel = .init()

  var body: some View {
    NavigationStack {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              myAnimeListId: self.myAnimeListId
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
                myAnimeListId: self.myAnimeListId
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
                myAnimeListId: self.myAnimeListId
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case let .loaded(coverUrls):
        TabView {
          ForEach(coverUrls, id: \.self) { coverUrl in
            AsyncImage(
              url: coverUrl,
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

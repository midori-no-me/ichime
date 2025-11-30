import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class ScreenshotCardsSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<URL>)
  }

  private(set) var state: State = .idle

  private let showService: ShowService
  private let myAnimeListId: Int

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    myAnimeListId: Int
  ) {
    self.showService = showService
    self.myAnimeListId = myAnimeListId
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let screenshots = try await showService.getScreenshots(
        myAnimeListId: self.myAnimeListId
      )

      if screenshots.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(.loaded(screenshots))
      }
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

struct ScreenshotCardsSection: View {
  @State private var viewModel: ScreenshotCardsSectionViewModel

  @State private var selectedScreenshot: URL? = nil
  @State private var showSheet: Bool = false

  init(myAnimeListId: Int) {
    self.viewModel = .init(myAnimeListId: myAnimeListId)
  }

  var body: some View {
    SectionWithCards(title: "Скриншоты") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          ScreenshotCardHStackInteractiveSkeleton()
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }

        case .loading:
          ScreenshotCardHStackInteractiveSkeleton()

        case let .loadingFailed(error):
          ScreenshotCardHStackContentUnavailable {
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

        case .loadedButEmpty:
          ScreenshotCardHStackContentUnavailable {
            Label("Пусто", systemImage: "rectangle.on.rectangle.angled")
          } description: {
            Text("У этого тайтла ещё нет скриншотов")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(screenshots):
          ScreenshotCardHStack(
            cards: screenshots.elements,
            loadMore: nil
          ) { screenshot in
            ScreenshotCard(
              imageURL: screenshot,
              onOpen: {
                self.selectedScreenshot = screenshot
                self.showSheet = true
              }
            )
          }
          .fullScreenCover(isPresented: self.$showSheet) {
            NavigationStack {
              TabView(selection: self.$selectedScreenshot) {
                ForEach(screenshots, id: \.self) { screenshot in
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
            .background(.thickMaterial)
          }
        }
      }
      .scrollClipDisabled()
      .scrollIndicators(.hidden)
    }
  }
}

import SwiftUI

struct ShowCardHStack<InputData: Hashable & Equatable, Content: View>: View {
  let cards: [InputData]
  let loadMore: (() async -> Void)?
  let renderCard: (InputData) -> Content
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
      ForEach(self.cards, id: \.self) { card in
        self.renderCard(card)
          .aspectRatio(ShowCard.RECOMMENDED_ASPECT_RATIO, contentMode: .fit)
          .containerRelativeFrame(
            .horizontal,
            count: horizontalSizeClass == .regular ? ShowCard.RECOMMENDED_COUNT_PER_ROW_REGULAR : ShowCard.RECOMMENDED_COUNT_PER_ROW_COMPACT,
            span: 1,
            spacing: ShowCard.RECOMMENDED_SPACING
          )
          .task {
            if let loadMore, cards.last == card {
              await loadMore()
            }
          }
      }
    }
  }
}

struct ShowCardHStackInteractiveSkeleton: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    ShowCardHStack(
      cards: Array(1...(horizontalSizeClass == .regular ? ShowCard.RECOMMENDED_COUNT_PER_ROW_REGULAR : ShowCard.RECOMMENDED_COUNT_PER_ROW_COMPACT)),
      loadMore: nil
    ) { index in
      ShowCard.placeholder()
        .focusable()
    }
  }
}

struct ShowCardHStackContentUnavailable<Label: View, Description: View, Actions: View>: View {
  private let label: () -> Label
  private let description: () -> Description
  private let actions: () -> Actions
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder description: @escaping () -> Description = { EmptyView() },
    @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
  ) {
    self.label = label
    self.description = description
    self.actions = actions
  }

  var body: some View {
    ShowCardHStack(
      cards: Array(1...(horizontalSizeClass == .regular ? ShowCard.RECOMMENDED_COUNT_PER_ROW_REGULAR : ShowCard.RECOMMENDED_COUNT_PER_ROW_COMPACT)),
      loadMore: nil
    ) { index in
      ShowCard.placeholder()
    }
    .mask(
      LinearGradient(
        gradient: .init(colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.2)]),
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .overlay(alignment: .center) {
      ContentUnavailableView {
        self.label()
      } description: {
        self.description()
      } actions: {
        self.actions()
      }
    }
  }
}

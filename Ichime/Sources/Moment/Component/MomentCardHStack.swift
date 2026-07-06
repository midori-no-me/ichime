import SwiftUI

struct MomentCardHStack<InputData: Hashable & Equatable, Content: View>: View {
  let cards: [InputData]
  let isCompact: Bool
  let loadMore: (() async -> Void)?
  let renderCard: (_ data: InputData, _ isCompact: Bool) -> Content

  var body: some View {
    LazyHStack(alignment: .top, spacing: MomentCardRaw.RECOMMENDED_SPACING) {
      ForEach(self.cards, id: \.self) { card in
        self.renderCard(card, self.isCompact)
          .containerRelativeFrame(
            .horizontal,
            count: self.isCompact
              ? MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_COMPACT : MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_EXPANDED,
            span: 1,
            spacing: MomentCardRaw.RECOMMENDED_SPACING
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

struct MomentCardHStackInteractiveSkeleton: View {
  let isCompact: Bool

  var body: some View {
    MomentCardHStack(
      cards: Array(
        1...(self.isCompact
          ? MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_COMPACT : MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_EXPANDED)
      ),
      isCompact: self.isCompact,
      loadMore: nil
    ) { _, isCompact in
      Button(action: {}) {
        MomentCardRaw.placeholder(isCompact: isCompact)
      }
      .buttonStyle(.borderless)
    }
  }
}

struct MomentCardHStackContentUnavailable<Label: View, Description: View, Actions: View>: View {
  private let isCompact: Bool
  private let label: () -> Label
  private let description: () -> Description
  private let actions: () -> Actions

  init(
    isCompact: Bool,
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder description: @escaping () -> Description = { EmptyView() },
    @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
  ) {
    self.isCompact = isCompact
    self.label = label
    self.description = description
    self.actions = actions
  }

  var body: some View {
    MomentCardHStack(
      cards: Array(
        1...(self.isCompact
          ? MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_COMPACT : MomentCardRaw.RECOMMENDED_COUNT_PER_ROW_EXPANDED)
      ),
      isCompact: self.isCompact,
      loadMore: nil
    ) { _, isCompact in
      VStack {
        MomentCardRaw.placeholder(isCompact: isCompact)
      }
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

#Preview {
  NavigationStack {
    ScrollView(.vertical) {
      VStack(spacing: 64) {
        SectionWithCards(title: "Interactive Skeleton") {
          ScrollView(.horizontal) {
            MomentCardHStackInteractiveSkeleton(isCompact: false)
          }
        }

        SectionWithCards(title: "Content Unavailable") {
          ScrollView(.horizontal) {
            MomentCardHStackContentUnavailable(isCompact: false) {
              Label("Пусто", systemImage: "rectangle.on.rectangle.angled")
            } description: {
              Text("Ничего не нашлось")
            } actions: {
              Button(action: {}) {
                Text("Обновить")
              }
            }
          }
        }
      }
    }
  }
}

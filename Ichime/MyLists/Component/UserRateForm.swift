import Combine
import ScraperAPI
import SwiftUI

extension ScraperAPI.Types.UserRateStatus {
  var displayName: String {
    switch self {
    case .planned:
      return String(localized: "Запланировано")
    case .watching:
      return String(localized: "Смотрю")
    case .completed:
      return String(localized: "Просмотрено")
    case .onHold:
      return String(localized: "Отложено")
    case .dropped:
      return String(localized: "Брошено")
    case .deleted:
      return String(localized: "Удалить из списка")
    }
  }

  var statusDisplayName: String {
    switch self {
    case .planned:
      return String(localized: "Запланировано")
    case .watching:
      return String(localized: "Смотрю")
    case .completed:
      return String(localized: "Просмотрено")
    case .onHold:
      return String(localized: "Отложено")
    case .dropped:
      return String(localized: "Брошено")
    case .deleted:
      return String(localized: "Добавить в список")
    }
  }
}

enum Score: Int, CaseIterable {
  case zero = 0
  case ten = 10
  case nine = 9
  case eight = 8
  case seven = 7
  case six = 6
  case five = 5
  case four = 4
  case three = 3
  case two = 2
  case one = 1

  var description: String {
    switch self {
    case .zero:
      return "—"
    case .ten:
      return String(localized: "10 — Шедевр")
    case .nine:
      return String(localized: "9 — Великолепно")
    case .eight:
      return String(localized: "8 — Очень хорошо")
    case .seven:
      return String(localized: "7 — Хорошо")
    case .six:
      return String(localized: "6 — Неплохо")
    case .five:
      return String(localized: "5 — Средне")
    case .four:
      return String(localized: "4 — Плохо")
    case .three:
      return String(localized: "3 — Очень плохо")
    case .two:
      return String(localized: "2 — Ужасно")
    case .one:
      return String(localized: "1 — Отвратительно")
    }
  }
}

struct UserRateForm: View {
  @FocusState var isFocused

  @State private var score: Int = 0
  @State private var currentEpisode: String = "0"
  @State private var status: ScraperAPI.Types.UserRateStatus = .planned
  @State private var comment: String = ""
  @State private var isDeleteDialogOpen = false

  let onSubmit: (_ userRate: ScraperAPI.Types.UserRate) -> Void
  let onRemove: () -> Void
  let totalEpisodes: String

  init(
    _ userRate: ScraperAPI.Types.UserRate,
    totalEpisodes: String,
    onSubmit: @escaping (_: ScraperAPI.Types.UserRate) -> Void,
    onRemove: @escaping () -> Void
  ) {
    self.totalEpisodes = totalEpisodes
    self.onSubmit = onSubmit
    self.onRemove = onRemove
    _score = State(initialValue: userRate.score)
    _currentEpisode = State(initialValue: String(userRate.currentEpisode))
    _status = State(initialValue: userRate.status)
    _comment = State(initialValue: userRate.comment)
  }

  var body: some View {
    VStack {
      Form {
        Picker("Оценка", selection: self.$score) {
          ForEach(Score.allCases, id: \.self) { score in
            Text(score.description)
              .tag(score.rawValue)
          }
        }
        Picker("Статус", selection: self.$status) {
          ForEach(ScraperAPI.Types.UserRateStatus.allCases, id: \.self) { status in
            Text(status.displayName)
          }
        }
        LabeledContent("Текущий эпизод") {
          HStack {
            TextField("Текущий эпизод", text: self.$currentEpisode).keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .focused(self.$isFocused)
              .onChange(of: self.isFocused) {
                if self.isFocused {
                  DispatchQueue.main.async {
                    UIApplication.shared.sendAction(
                      #selector(UIResponder.selectAll(_:)),
                      to: nil,
                      from: nil,
                      for: nil
                    )
                  }
                }
              }
            Text("/ \(self.totalEpisodes)")
          }
        }

        Button("Удалить из списка", role: .destructive) {
          self.isDeleteDialogOpen = true
        }
        .confirmationDialog(
          "Вы точно уверены, что хотите удалить?",
          isPresented: self.$isDeleteDialogOpen
        ) {
          Button("Да, удалить", role: .destructive) {
            self.onRemove()
          }
          Button("Отмена", role: .cancel) {
            self.isDeleteDialogOpen = false
          }
        }
      }.toolbar {
        ToolbarItem(
          placement: .confirmationAction,
          content: {
            Button(action: {
              self.onSubmit(
                .init(
                  score: self.score,
                  currentEpisode: Int(self.currentEpisode) ?? 0,
                  status: self.status,
                  comment: self.comment
                )
              )
            }) {
              Text("Сохранить")
            }
          }
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    UserRateForm(
      .init(
        score: 6,
        currentEpisode: 3,
        status: .watching,
        comment:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas id felis ut lorem tempus ornare. Morbi nec enim vel ex lobortis blandit quis ut lectus. Nam gravida mi eu elit posuere tincidunt."
      ),
      totalEpisodes: "??",
      onSubmit: { print($0) },
      onRemove: {}
    )
  }
}

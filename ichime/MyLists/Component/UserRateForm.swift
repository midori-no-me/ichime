//
//  UserRateForm.swift
//  ichime
//
//  Created by Nikita Nafranets on 26.01.2024.
//

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
    let onSubmit: (_ userRate: ScraperAPI.Types.UserRate) -> Void
    let onRemove: () -> Void
    let totalEpisodes: String
    @State private var score: Int = 0
    @State private var currentEpisode: String = "0"
    @State private var status: ScraperAPI.Types.UserRateStatus = .planned
    @State private var comment: String = ""

    @FocusState var isFocused

    @State private var isDeleteDialogOpen = false
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
                Picker("Оценка", selection: $score) {
                    ForEach(Score.allCases, id: \.self) { score in
                        Text(score.description)
                            .tag(score.rawValue)
                    }
                }
                Picker("Статус", selection: $status) {
                    ForEach(ScraperAPI.Types.UserRateStatus.allCases, id: \.self) { status in
                        Text(status.displayName)
                    }
                }
                LabeledContent("Текущий эпизод") {
                    HStack {
                        TextField("Текущий эпизод", text: $currentEpisode).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isFocused)
                            .onChange(of: isFocused) {
                                if isFocused {
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
                        Text("/ \(totalEpisodes)")
                    }
                }
                Section("Ваша заметка") {
                    TextEditor(text: $comment)
                }
                Button("Удалить из списка", role: .destructive) {
                    isDeleteDialogOpen = true
                }
                .confirmationDialog("Вы точно уверены, что хотите удалить?", isPresented: $isDeleteDialogOpen) {
                    Button("Да, удалить", role: .destructive) {
                        onRemove()
                    }
                    Button("Отмена", role: .cancel) {
                        isDeleteDialogOpen = false
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button(action: {
                        onSubmit(.init(score: self.score, currentEpisode: Int(self.currentEpisode) ?? 0,
                                       status: self.status, comment: self.comment))
                    }) {
                        Text("Сохранить")
                    }
                })
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserRateForm(
            .init(score: 6, currentEpisode: 3, status: .watching, comment: "Test"),
            totalEpisodes: "??",
            onSubmit: { print($0) },
            onRemove: {}
        )
    }
}

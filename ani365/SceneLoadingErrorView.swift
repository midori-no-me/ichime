//
//  SceneLoadingErrorView.swift
//  ani365
//
//  Created by p.flaks on 06.01.2024.
//

import SwiftUI

struct SceneLoadingErrorView: View {
    let loadingError: Error
    let reload: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
            Text(self.loadingError.localizedDescription)
        }
        .textSelection(.enabled)

        Button {
            Task {
                await self.reload()
            }
        } label: {
            Text("Попробовать ещё раз")
        }
        .padding(.top, 22)
    }
}

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
        VStack(alignment: .center, spacing: 18) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)

            VStack {
                Text("Ошибка при загрузке:")
                    .foregroundStyle(Color.secondary)

                Text(self.loadingError.localizedDescription)
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
            }.textSelection(.enabled)

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
}

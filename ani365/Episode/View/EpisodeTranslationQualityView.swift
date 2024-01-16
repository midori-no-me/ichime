//
//  EpisodeTranslationQualityView.swift
//  ani365
//
//  Created by p.flaks on 17.01.2024.
//

import SwiftUI

struct EpisodeTranslationQualityView: View {
    let translationTeam: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        print("asd")
                    }) {
                        Text("720p")
                    }

                    Button(action: {
                        print("asd")
                    }) {
                        Text("1080p")
                    }
                } footer: {
                    Text("AirPlay не доступен для серий с софтсабом.")
                }
            }
            .navigationTitle(translationTeam)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EpisodeTranslationQualityView(
        translationTeam: "Crunchyroll"
    )
}

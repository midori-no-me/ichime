//
//  SeriesCategoryRow.swift
//  ani365
//
//  Created by p.flaks on 02.01.2024.
//

import SwiftUI

struct ShowCategoryRow<Content>: View where Content: View {
    let title: String
    let description: String
    let shows: [Show]

    @ViewBuilder let navigationLinkDestination: Content

    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: navigationLinkDestination) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(Image(systemName: "chevron.forward"))
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())

            Text(description)
                .font(.subheadline)
                .padding(.horizontal)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(shows, id: \.self) { show in
                        ShowCard(show: show)
                            .frame(width: 110, height: 220)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 18)
        }
    }
}

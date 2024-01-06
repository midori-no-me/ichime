//
//  SearchShowsView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct SearchShowsView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Text("Searching for \(searchText)")
        }
        .navigationTitle("Поиск")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Название тайтла")
    }
}

#Preview {
    SearchShowsView()
}

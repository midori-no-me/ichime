//
//  ShowView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import CachedAsyncImage
import SwiftUI

struct EpisodeView: View {
    let episodeId: Int

    @State private var episode: Episode?
    @State private var isLoading = true
    @State private var loadingError: Error?

    var body: some View {
        Group {

        }
    }

}

#Preview {
    NavigationStack {
        EpisodeView(episodeId: 291395)
    }
}


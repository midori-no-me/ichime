//
//  OverviewView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct OverviewView: View {
    var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                Text("overview body")
            }
            .navigationTitle("Обзор")
        }
    }
}

#Preview {
    OverviewView()
}

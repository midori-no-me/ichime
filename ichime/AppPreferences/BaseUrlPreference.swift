//
//  CommonPreferences.swift
//  ichime
//
//  Created by p.flaks on 28.01.2024.
//

import Foundation
import SwiftUI

class BaseUrlPreference: ObservableObject {
    @AppStorage("anime365-base-url") var url: URL = URL(string: "https://anime365.ru")!

    static func getAllPossibleWebsiteBaseDomains() -> [URL] {
        return [
            URL(string: "https://anime365.ru")!,
            URL(string: "https://anime-365.ru")!,
            URL(string: "https://smotret-anime.com")!,
            URL(string: "https://smotret-anime.online")!,
        ]
    }
}

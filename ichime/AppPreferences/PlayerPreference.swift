//
//  PlayerPreference.swift
//  ichime
//
//  Created by n.nafranets on 20.09.2024.
//

import Foundation
import SwiftUI


class PlayerPreference: ObservableObject {
    @AppStorage("defaultPlayer") var selectedPlayer: Player = .infuse
    
    enum Player: String, CaseIterable {
        case iOS
        case infuse
    }
}

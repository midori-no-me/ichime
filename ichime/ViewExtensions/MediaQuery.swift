//
//  MediaQuery.swift
//  Ichime
//
//  Created by Nikita Nafranets on 20.03.2024.
//

import Foundation
import UIKit

extension UIDevice {
    var isPhoneOrTv: Bool {
        return userInterfaceIdiom == .phone || userInterfaceIdiom == .tv
    }
}

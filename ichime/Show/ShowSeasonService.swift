//
//  ShowSeasonService.swift
//  Ichime
//
//  Created by p.flaks on 31.03.2024.
//

import Foundation

enum SeasonName: String {
    case winter
    case spring
    case summer
    case autumn

    func getLocalizedTranslation() -> String {
        switch self {
        case .winter:
            "Зима"
        case .spring:
            "Весна"
        case .summer:
            "Лето"
        case .autumn:
            "Осень"
        }
    }

    func getApiName() -> String {
        switch self {
        case .winter:
            "winter"
        case .spring:
            "spring"
        case .summer:
            "summer"
        case .autumn:
            "autumn"
        }
    }
}

struct ShowSeasonService {
    public static let NEXT_SEASON = 1
    public static let CURRENT_SEASON = 0
    public static let PREVIOUS_SEASON = -1

    private let currentDate: Date

    init() {
        self.currentDate = Date()
    }

    /// 1 = next season
    /// 0 = current season
    /// -1 = previous season
    func getRelativeSeason(shift: Int) -> (Int, SeasonName) {
        let shiftedDate = Calendar.current.date(byAdding: .month, value: shift * 3, to: self.currentDate)!
        let shiftedYear = Calendar.current.component(.year, from: shiftedDate)
        let shiftedMonthNumber = Calendar.current.component(.month, from: shiftedDate)

        let yearAndSeason = switch shiftedMonthNumber {
        case 1, 2, 3: // January, February, March
            (shiftedYear, SeasonName.winter)
        case 4, 5, 6: // April, May, June
            (shiftedYear, SeasonName.spring)
        case 7, 8, 9: // July, August, September
            (shiftedYear, SeasonName.summer)
        default: // October, November, December
            (shiftedYear, SeasonName.autumn)
        }

        return yearAndSeason
    }
}

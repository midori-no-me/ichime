//
//  DateUtils.swift
//  Ichime
//
//  Created by p.flaks on 19.03.2024.
//

import Foundation

public func formatRelativeDate(_ releaseDate: Date?) -> String {
    guard let releaseDate = releaseDate else {
        return "???"
    }

    let now = Date()
    let calendar = Calendar.current

    if calendar.isDateInToday(releaseDate) || calendar.isDateInYesterday(releaseDate) {
        let formatStyle = Date.RelativeFormatStyle(presentation: .named)

        return releaseDate.formatted(formatStyle)
    } else {
        let formatter = DateFormatter()

        formatter.setLocalizedDateFormatFromTemplate("d MMMM")

        if !calendar.isDate(releaseDate, equalTo: now, toGranularity: .year) {
            formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        }

        return formatter.string(from: releaseDate)
    }
}

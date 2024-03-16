//
//  Anime365.swift
//  ichime
//
//  Created by p.flaks on 02.01.2024.
//

import Anime365ApiClient
import Foundation

func convertApiDateStringToDate(string: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = format

    let date = dateFormatter.date(from: string)

    return date
}

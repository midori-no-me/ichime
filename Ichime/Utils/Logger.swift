//
//  Logger.swift
//  Ichime
//
//  Created by Nikita Nafranets on 20.03.2024.
//

import os

func createLogger(category: String) -> Logger {
  Logger(subsystem: ServiceLocator.applicationId, category: category)
}

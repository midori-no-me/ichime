import os

func createLogger(category: String) -> Logger {
  Logger(subsystem: ServiceLocator.applicationId, category: category)
}

import Foundation

func extractIdentifiersFromURL(_ url: URL) -> (
  seriesID: Int?,
  episodeID: Int?
) {
  if url.pathComponents.count < 2 {
    return (nil, nil)
  }

  if url.pathComponents[1] != "catalog" {
    return (nil, nil)
  }

  var seriesID: Int?

  if let extractedSeriesID = url.pathComponents[2].firstMatch(of: /(?<id>\d+?)$/)?.output.id {
    seriesID = Int(extractedSeriesID)
  }

  var episodeID: Int?

  if let extractedEpisodeID = url.pathComponents[3].firstMatch(of: /(?<id>\d+?)$/)?.output.id {
    episodeID = Int(extractedEpisodeID)
  }

  return (seriesID, episodeID)
}

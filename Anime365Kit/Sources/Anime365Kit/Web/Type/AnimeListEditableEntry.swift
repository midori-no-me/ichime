import Foundation
import SwiftSoup

public struct AnimeListEditableEntry {
  public let episodesWatched: Int
  public let status: AnimeListEntryStatus
  public let score: Int?
  public let commentary: String?

  init(htmlElement: Element) throws(WebClientTypeNormalizationError) {
    if let episodesWatchedString = try? htmlElement.select("input#UsersRates_episodes").first()?.attr("value"),
      let episodesWatched = Int(episodesWatchedString)
    {
      self.episodesWatched = episodesWatched
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize score because there is no `input#UsersRates_episodes` element or it is not valid Int"
      )
    }

    if let statusString = try? htmlElement.select("select#UsersRates_status option[selected]").first()?.attr("value"),
      let statusInt = Int(statusString), let status = AnimeListEntryStatus.create(fromNumericID: statusInt)
    {
      self.status = status
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize status because there is no `select#UsersRates_status option[selected]` element, or its `value` attribute is not valid Int, or Int is not valid status"
      )
    }

    if let scoreString = try? htmlElement.select("#UsersRates_score option[selected]").first()?.attr("value"),
      let score = Int(scoreString)
    {
      self.score = score > 0 ? score : nil
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize score string because there is no `#UsersRates_score option[selected]` element"
      )
    }

    if let commentary = try? htmlElement.select("#UsersRates_comment").first()?.text() {
      self.commentary = commentary
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize commentary because there is no `#UsersRates_comment` element"
      )
    }
  }

  private init(
    episodesWatched: Int,
    status: AnimeListEntryStatus,
    score: Int?,
    commentary: String?
  ) {
    self.episodesWatched = episodesWatched
    self.status = status
    self.score = score
    self.commentary = commentary
  }

  static func createNotInList() -> Self {
    Self(
      episodesWatched: 0,
      status: .notInList,
      score: nil,
      commentary: nil
    )
  }
}

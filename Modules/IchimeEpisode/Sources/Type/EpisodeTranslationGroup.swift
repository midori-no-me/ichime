public struct EpisodeTranslationGroup: Identifiable {
  // MARK: Properties

  public let groupType: EpisodeTranslationGroupType
  public let episodeTranslationInfos: [EpisodeTranslationInfo]

  // MARK: Computed Properties

  public var id: EpisodeTranslationGroupType {
    self.groupType
  }
}

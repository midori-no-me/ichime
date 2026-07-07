public struct EpisodeTranslationGroup: Identifiable {
  public let groupType: EpisodeTranslationGroupType
  public let episodeTranslationInfos: [EpisodeTranslationInfo]

  public var id: EpisodeTranslationGroupType {
    self.groupType
  }
}

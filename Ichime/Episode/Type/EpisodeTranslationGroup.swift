struct EpisodeTranslationGroup: Identifiable {
  let groupType: EpisodeTranslationGroupType
  let episodeTranslationInfos: [EpisodeTranslationInfo]

  var id: EpisodeTranslationGroupType {
    self.groupType
  }
}

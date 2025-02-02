import SwiftUI

final class HiddenTranslationsPreferenceState: ObservableObject {
  @AppStorage("hide_translations_russian_subtitles") private var hideRussianSubtitles: Bool = false
  @AppStorage("hide_translations_russian_voiceover") private var hideRussianVoiceover: Bool = false
  @AppStorage("hide_translations_english_subtitles") private var hideEnglishSubtitles: Bool = false
  @AppStorage("hide_translations_english_voiceover") private var hideEnglishVoiceover: Bool = false
  @AppStorage("hide_translations_japanese") private var hideJapanese: Bool = false
  @AppStorage("hide_translations_other") private var hideOther: Bool = false

  func getPreference() -> HiddenTranslationsPreference {
    HiddenTranslationsPreference(
      hideRussianSubtitles: self.hideRussianSubtitles,
      hideRussianVoiceover: self.hideRussianVoiceover,
      hideEnglishSubtitles: self.hideEnglishSubtitles,
      hideEnglishVoiceover: self.hideEnglishVoiceover,
      hideJapanese: self.hideJapanese,
      hideOther: self.hideOther
    )
  }
}

struct HiddenTranslationsPreference: Equatable {
  let hideRussianSubtitles: Bool
  let hideRussianVoiceover: Bool
  let hideEnglishSubtitles: Bool
  let hideEnglishVoiceover: Bool
  let hideJapanese: Bool
  let hideOther: Bool
}

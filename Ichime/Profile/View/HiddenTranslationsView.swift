import SwiftUI

struct HiddenTranslationsView: View {
  @AppStorage("hide_translations_russian_subtitles") private var hideRussianSubtitles: Bool = false
  @AppStorage("hide_translations_russian_voiceover") private var hideRussianVoiceover: Bool = false
  @AppStorage("hide_translations_english_subtitles") private var hideEnglishSubtitles: Bool = false
  @AppStorage("hide_translations_english_voiceover") private var hideEnglishVoiceover: Bool = false
  @AppStorage("hide_translations_japanese") private var hideJapanese: Bool = false
  @AppStorage("hide_translations_other") private var hideOther: Bool = false

  var body: some View {
    Form {
      Section {
        Toggle("Русские субтитры", isOn: self.$hideRussianSubtitles)
        Toggle("Русская озвучка", isOn: self.$hideRussianVoiceover)
        Toggle("Английские субтитры", isOn: self.$hideEnglishSubtitles)
        Toggle("Английская озвучка", isOn: self.$hideEnglishVoiceover)
        Toggle("Японский", isOn: self.$hideJapanese)
        Toggle("Прочие переводы", isOn: self.$hideOther)
      } header: {
        Text("Скрытые переводы")
      } footer: {
        Text("Выбранные вами переводы будут скрыты из списка доступных переводов.")
      }
    }
  }
}

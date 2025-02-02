import SwiftUI

struct CardWithExpandableText: View {
  static let RECOMMENDED_SPACING: CGFloat = 40

  let title: String
  let text: String

  @State private var isSheetPresented = false

  var body: some View {
    Button {
      self.isSheetPresented.toggle()
    } label: {
      VStack(alignment: .leading, spacing: 10) {
        Group {
          Text(self.title)
            .lineLimit(1)
            .truncationMode(.tail)
            .font(.body)
            .fontWeight(.bold)

          Text(self.text)
            .lineLimit(5, reservesSpace: true)
            .truncationMode(.tail)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(40)
    }
    .sheet(isPresented: self.$isSheetPresented) {
      CardWithExpandableTextSheet(
        title: self.title,
        text: self.text
      )
    }
    .buttonStyle(.card)
  }
}

private struct CardWithExpandableTextSheet: View {
  let title: String
  let text: String

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView([.vertical]) {
        Text(self.text)
          .frame(maxWidth: .infinity, alignment: .leading)
          .scenePadding()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Закрыть") {
            self.dismiss()
          }
        }
      }
      .navigationTitle(self.title)
    }
  }
}

#Preview {
  NavigationStack {
    VStack(alignment: .leading, spacing: CardWithExpandableText.RECOMMENDED_SPACING) {
      CardWithExpandableText(
        title: "Short title",
        text: "Short text, asdasdasdasdasdsadasdasd"
      )

      CardWithExpandableText(
        title: "Short title",
        text: "Short text, asdasdasdasdasdsadasdasd"
      )

      CardWithExpandableText(
        title:
          "Очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень-очень длинное описание",
        text:
          "Владыка Тьмы повержен, и вместе с тем подошло к концу путешествие героя Химмеля и его отряда. Шли годы, все они разбрелись кто куда, но только эльфийке-долгожительнице Фрирен десятилетия показались мгновением, и однажды на её плечи легла тяжесть осознания того, что людской век ужасно скоротечен. В конце концов эльфийка решает во чтобы то ни стало исполнить предсмертные желания своих друзей. Но сможет ли она это сделать? И как сильно её потрясёт череда неизбежных потерь? Фрирен пускается в путь, чтобы это выяснить.\n\nОдержав победу над Королём демонов, отряд героя Химмеля вернулся домой. Приключение, растянувшееся на десятилетие, подошло к завершению. Волшебница-эльф Фрирен и её отважные товарищи принесли людям мир и разошлись в разные стороны, чтобы спокойно прожить остаток жизни. Однако не всех членов отряда ждёт одинаковая участь. Для эльфов время течёт иначе, поэтому Фрирен вынужденно становится свидетелем того, как её спутники один за другим постепенно уходят из жизни. Девушка осознала, что годы, проведённые в отряде героя, пронеслись в один миг, как падающая звезда в бескрайнем космосе её жизни, и столкнулась с сожалениями об упущенных возможностях. Сможет ли она смириться со смертью друзей и понять, что значит жизнь для окружающих её людей? Фрирен начинает новое путешествие, чтобы найти ответ."
      )
    }
    .scenePadding()
  }
}

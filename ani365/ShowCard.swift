import SwiftUI

struct ShowCard: View {
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(
                url: show.posterUrl!,
                transaction: .init(animation: .easeInOut)
            ) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                        .resizable()
                        .scaledToFit() // not .scaledToFill
                        .clipped()
                case .failure:
                    VStack {
                        Image(systemName: "wifi.slash")
                    }.scaledToFit()

                @unknown default:
                    EmptyView()
                }
            }
            .shadow(color: Color.primary.opacity(0.3), radius: 1)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            //            .fixedSize(horizontal: false, vertical: true)

            Text(show.title.translated.japaneseRomaji ?? show.title.full)
                .font(.body)
        }.frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

// #Preview {
//    VStack {
//        ShowCard(
//            show: Show(
//                id: 123,
//                title: Show.Title(
//                    full: "Shangri-La Frontier: Kusoge Hunter, Kamige ni Idoman to su",
//                    translated: Show.Title.TranslatedTitles(
//                        russian: nil,
//                        english: nil,
//                        japanese: nil,
//                        japaneseRomaji: nil
//                    )
//                ),
//                posterUrl: URL(string: "https://loremflickr.com/400/600"),
//                websiteUrl: URL(string: "https://loremflickr.com/400/600")!
//            )
//        )
//    }.frame(width: 400)
//        .border(Color.red)
// }

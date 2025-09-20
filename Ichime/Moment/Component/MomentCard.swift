import SwiftUI
import ThirdPartyVideoPlayer

struct MomentCard: View {
  let moment: Moment
  let displayShowTitle: Bool

  private let momentService: MomentService = ApplicationDependency.container.resolve()

  @AppStorage("defaultPlayer") private var selectedPlayer: ThirdPartyVideoPlayerType = .infuse

  @State private var showErrorAlert: Bool = false
  @State private var error: Error? = nil

  var body: some View {
    Button(action: {
      Task {
        do {
          let videoURL = try await momentService.getMomentVideoURL(momentId: self.moment.id)

          let externalPlayerUniversalLink = DeepLinkFactory.buildUniversalLinkUrl(
            externalPlayerType: self.selectedPlayer,
            videoUrl: videoURL,
            subtitlesUrl: nil
          )

          if !UIApplication.shared.canOpenURL(externalPlayerUniversalLink) {
            print("Opening App Store: \(self.selectedPlayer.appStoreUrl)")

            await UIApplication.shared.open(self.selectedPlayer.appStoreUrl)

            return
          }

          print("Opening external player: \(externalPlayerUniversalLink.absoluteString)")

          await UIApplication.shared.open(externalPlayerUniversalLink)
        }
        catch {
          self.error = error
          self.showErrorAlert = true
        }
      }
    }) {
      VStack {
        AsyncImage(
          url: self.moment.thumbnailUrl,
          transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
        ) { phase in
          switch phase {
          case .empty:
            Color.clear

          case let .success(image):
            image
              .resizable()
              .scaledToFit()

          case .failure:
            Image(systemName: "photo")
              .font(.title)
              .foregroundStyle(Color.white)

          @unknown default:
            Color.clear
          }
        }
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.black)
        .hoverEffect(.highlight)
      }

      self.cardLabelView()
        .lineLimit(self.displayShowTitle ? 3 : 1, reservesSpace: true)
        .multilineTextAlignment(.center)
    }
    .buttonStyle(.borderless)
    .alert("Ошибка при открытии момента", isPresented: self.$showErrorAlert, presenting: self.error) { _ in
      Button(action: {
        self.error = nil
      }) {
        Text("ОК")
      }
    } message: { error in
      Text(error.localizedDescription)
    }
  }

  private func cardLabelView() -> Text {
    if self.displayShowTitle {
      return Text("\(self.moment.title) \(Text(" " + self.moment.showTitle).foregroundStyle(.secondary))")
    }

    return Text(self.moment.title)
  }
}

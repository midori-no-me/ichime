import SwiftUI
import ThirdPartyVideoPlayer

struct MomentCardRaw: View {
  static let RECOMMENDED_SPACING: CGFloat = 64
  static let RECOMMENDED_IMAGE_ASPECT_RATIO: CGSize = .init(width: 16, height: 9)
  static let RECOMMENDED_COUNT_PER_ROW_EXPANDED: Int = 3
  static let RECOMMENDED_COUNT_PER_ROW_COMPACT: Int = 4
  static let RECOMMENDED_LABEL_LINE_LIMIT_COMPACT = 1
  static let RECOMMENDED_LABEL_LINE_LIMIT_EXPANDED = 3

  private let coverURL: URL?
  private let isCompact: Bool
  private let bottomChips: [String]
  @ViewBuilder private let label: () -> Text

  init(
    coverURL: URL?,
    isCompact: Bool,
    bottomChips: [String],
    @ViewBuilder label: @escaping () -> Text,
  ) {
    self.coverURL = coverURL
    self.isCompact = isCompact
    self.bottomChips = bottomChips
    self.label = label
  }

  var body: some View {
    ZStack {
      AsyncImage(
        url: self.coverURL,
        transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
      ) { phase in
        switch phase {
        case .empty:
          ImagePlaceholder()

        case let .success(image):
          image
            .resizable()
            .scaledToFit()

        case .failure:
          Image(systemName: "photo")
            .font(.title)
            .foregroundStyle(Color.white)

        @unknown default:
          ImagePlaceholder()
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .background(Color.black)
      .aspectRatio(Self.RECOMMENDED_IMAGE_ASPECT_RATIO, contentMode: .fit)

      VStack(alignment: .leading, spacing: 4) {
        if !self.bottomChips.isEmpty {
          HStack(alignment: .center, spacing: 4) {
            ForEach(self.bottomChips, id: \.self) { bottomChip in
              MomentCardChip(label: bottomChip)
            }
          }
          .padding(.bottom)
          .padding(.horizontal)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .bottomTrailing
      )
    }
    .hoverEffect(.highlight)

    self.label()
      .lineLimit(
        self.isCompact ? Self.RECOMMENDED_LABEL_LINE_LIMIT_COMPACT : Self.RECOMMENDED_LABEL_LINE_LIMIT_EXPANDED,
        reservesSpace: true
      )
      .frame(maxWidth: .infinity, alignment: .center)
      .multilineTextAlignment(.center)
  }

  static func placeholder(isCompact: Bool) -> some View {
    Self.init(
      coverURL: nil,
      isCompact: isCompact,
      bottomChips: [],
      label: {
        Text(String(repeating: " ", count: 50))
      }
    )
    .redacted(reason: .placeholder)
  }
}

private struct MomentCardChip: View {
  let label: String

  var body: some View {
    Text(self.label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.ultraThickMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

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
      MomentCardRaw(
        coverURL: self.moment.thumbnailUrl,
        isCompact: !self.displayShowTitle,
        bottomChips: [self.moment.duration.formatted(DurationShortFormatStyle())],
        label: {
          self.cardLabelView()
        }
      )
    }
    .buttonStyle(.borderless)
    .contextMenu {
      MomentCardContextMenu(momentId: self.moment.id)
    }
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
      return Text("\(self.moment.title) \(Text(self.moment.showTitle).foregroundStyle(.secondary))")
    }

    return Text(self.moment.title)
  }
}

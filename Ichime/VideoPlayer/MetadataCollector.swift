import AVFoundation
import Foundation
import UIKit

struct MetadataPlayer {
  /** большой заголовок в плеере */
  let title: String?
  /** надпись над заголовком */
  let subtitle: String?
  /** текст который открывается если нажать на title */
  let description: String?
  let genre: String?
  let image: Data?
  let year: Int?
}

struct MetadataCollector {
  static func createMetadataItems(for metadata: MetadataPlayer) -> [AVMetadataItem] {
    let mapping: [AVMetadataIdentifier: Any?] = [
      .commonIdentifierTitle: metadata.title,
      .iTunesMetadataTrackSubTitle: metadata.subtitle,
      .commonIdentifierArtwork: metadata.image != nil
        ? (UIImage(data: metadata.image!)?.pngData() as Any) : nil,
      .commonIdentifierDescription: metadata.description,
      .quickTimeMetadataGenre: metadata.genre,
      .identifier3GPUserDataRecordingYear: metadata.year,
    ]

    return mapping.compactMap { self.createMetadataItem(for: $0, value: $1) }
  }

  private static func createMetadataItem(
    for identifier: AVMetadataIdentifier,
    value: Any?
  ) -> AVMetadataItem? {
    guard let value else { return nil }
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value as? NSCopying & NSObjectProtocol
    // Specify "und" to indicate an undefined language.
    item.extendedLanguageTag = "und"
    return item.copy() as! AVMetadataItem
  }
}

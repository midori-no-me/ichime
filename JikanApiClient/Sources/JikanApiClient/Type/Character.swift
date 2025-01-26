import Foundation

public struct Character: Decodable {
  public struct Image: Decodable {
    public struct ImageFormat: Decodable {
      public let image_url: URL?
    }

    public let jpg: ImageFormat
  }

  public let mal_id: Int
  public let name: String
  public let images: Image
}

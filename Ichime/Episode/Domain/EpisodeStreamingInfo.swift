import Anime365ApiClient
import Foundation
import ScraperAPI

struct EpisodeStreamingInfo: Hashable, Identifiable {
  init(apiResponse: Anime365TranslationEmbed) {
    let websiteBaseUrl = ServiceLocator.websiteBaseUrl.absoluteString
    let cookies: HTTPCookieStorage = ApplicationDependency.container.resolve()

    let subtitleUrlGenerator = SubtitleUrlGenerator(
      websiteBaseUrl: websiteBaseUrl,
      cookies: cookies
    )
    var subtitles: EpisodeStreamingInfo.SubtitlesUrls? = nil

    if let vttUrlString = apiResponse.subtitlesVttUrl, let vttUrl = URL(string: vttUrlString),
      let subtitleUrl = subtitleUrlGenerator.generateSubtitleUrl(for: apiResponse.subtitlesUrl),
      let subsUrl = URL(string: subtitleUrl)
    {
      subtitles = EpisodeStreamingInfo.SubtitlesUrls(
        vtt: vttUrl,
        base: subsUrl
      )
    }

    id = apiResponse.embedUrl
    streamQualityOptions = apiResponse.stream.map { streamQualityOption in
      StreamQualityOption(
        id: streamQualityOption.height,
        height: streamQualityOption.height,
        urls: streamQualityOption.urls.map { streamUrlString in
          URL(string: streamUrlString)!
        }
      )
    }
    self.subtitles = subtitles
  }

  let id: String
  let streamQualityOptions: [StreamQualityOption]
  let subtitles: SubtitlesUrls?

  static func == (lhs: EpisodeStreamingInfo, rhs: EpisodeStreamingInfo) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  struct StreamQualityOption: Hashable, Identifiable {
    var id: Int

    let height: Int
    let urls: [URL]

    static func == (lhs: StreamQualityOption, rhs: StreamQualityOption) -> Bool {
      lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }

  struct SubtitlesUrls {
    let vtt: URL
    let base: URL
  }
}

struct SubtitleUrlGenerator {
  private let websiteBaseUrl: String
  private let cookies: HTTPCookieStorage

  init(websiteBaseUrl: String, cookies: HTTPCookieStorage) {
    self.websiteBaseUrl = websiteBaseUrl
    self.cookies = cookies
  }

  // Метод для получения URL для субтитров
  func generateSubtitleUrl(for subtitlesUrlString: String?) -> String? {
    guard let subtitlesUrlString = subtitlesUrlString else { return nil }

    // Если нет, продолжаем генерировать URL как раньше
    let episodeId = extractId(from: subtitlesUrlString)
    let domain = URL(string: websiteBaseUrl)?.host ?? ""
    let cookieToken = getCookieToken()

    // Формируем URL с параметрами
    let subtitleUrl =
      "https://anime365-subs-proxy-worker.dimensi.workers.dev/\(episodeId).ass?domain=\(domain)&cookie_token=\(cookieToken)"

    return subtitleUrl
  }

  // Функция для извлечения id из строки URL
  private func extractId(from urlString: String?) -> String {
    guard let urlString = urlString else { return "" }

    // Регулярное выражение для извлечения числа из строки
    let pattern = "(\\d+)"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(urlString.startIndex..<urlString.endIndex, in: urlString)

    if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
      if let range = Range(match.range(at: 1), in: urlString) {
        return String(urlString[range])
      }
    }
    return ""
  }

  // Функция для получения cookie_token
  private func getCookieToken() -> String {
    // Получаем значения для cookie по ключам
    let cookiesDict = [
      ScraperAPI.Session.Cookie.csrf.rawValue: cookies.cookie(for: .csrf)?.value,
      ScraperAPI.Session.Cookie.phpsessid.rawValue: cookies.cookie(for: .phpsessid)?.value,
      ScraperAPI.Session.Cookie.token.rawValue: cookies.cookie(for: .token)?.value,
    ]

    // Фильтруем пустые значения и формируем строку в формате "cookieName=cookieValue"
    let cookieString = cookiesDict.compactMap { key, value in
      guard let value = value else { return nil }
      return "\(key)=\(value)"
    }.joined(separator: "; ")

    return cookieString
  }
}

// Структура для работы с субтитрами
extension HTTPCookieStorage {
  func cookie(for type: ScraperAPI.Session.Cookie) -> HTTPCookie? {
    cookies?.first { $0.name == type.rawValue }
  }
}

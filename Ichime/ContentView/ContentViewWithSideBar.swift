import SwiftData
import SwiftUI

struct ContentViewWithSideBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @AppStorage(CurrentUserInfo.UserDefaultsKey.NAME) private var userName: String?
  @AppStorage(CurrentUserInfo.UserDefaultsKey.AVATAR_URL_PATH) private var avatarUrlPath: String?

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab("Главная", systemImage: "play.house", value: .home) {
        NavigationStackWithRouter {
          HomeView()
        }
      }

      Tab("К просмотру", systemImage: "play.square.stack", value: .currentlyWatching) {
        NavigationStackWithRouter {
          CurrentlyWatchingView()
        }
      }

      Tab("Календарь", systemImage: "calendar", value: .calendar) {
        NavigationStackWithRouter {
          CalendarView()
        }
      }

      Tab(value: .profile) {
        NavigationStackWithRouter {
          ProfileView()
        }
      } label: {
        Label(title: {
          if let userName {
            Text(userName)
          }
          else {
            Text("Профиль")
          }
        }) {
          if let avatarUrlPath = self.avatarUrlPath {
            AsyncImage(
              url: self.anime365BaseURL.appendingPathComponent(avatarUrlPath),
              transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
            ) { phase in
              switch phase {
              case .empty:
                Image(systemName: "person.circle")

              case let .success(image):
                Image(
                  uiImage:
                    image
                    .getUIImage(newSize: .init(width: 44, height: 44))!
                    .circle()
                )

              case .failure:
                Image(systemName: "person.circle")

              @unknown default:
                Image(systemName: "person.circle")
              }
            }
          }
          else {
            Image(systemName: "person.circle")
          }
        }
      }

      Tab("Поиск", systemImage: "magnifyingglass", value: .search, role: .search) {
        NavigationStackWithRouter {
          SearchShowsView()
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
  }
}

/// https://gist.github.com/brownsoo/1b772612b54c4dc58d88ae71aec19552
extension UIImage {
  public func round(_ radius: CGFloat) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let renderer = UIGraphicsImageRenderer(size: rect.size)
    let result = renderer.image { c in
      let rounded = UIBezierPath(roundedRect: rect, cornerRadius: radius)
      rounded.addClip()
      if let cgImage = self.cgImage {
        UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation).draw(in: rect)
      }
    }
    return result
  }

  public func circle() -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let renderer = UIGraphicsImageRenderer(size: rect.size)
    let result = renderer.image { c in
      let isPortrait = size.height > size.width
      let isLandscape = size.width > size.height
      let breadth = min(size.width, size.height)
      let breadthSize = CGSize(width: breadth, height: breadth)
      let breadthRect = CGRect(origin: .zero, size: breadthSize)
      let origin = CGPoint(
        x: isLandscape ? floor((size.width - size.height) / 2) : 0,
        y: isPortrait ? floor((size.height - size.width) / 2) : 0
      )
      let circle = UIBezierPath(ovalIn: breadthRect)
      circle.addClip()
      if let cgImage = self.cgImage?.cropping(to: CGRect(origin: origin, size: breadthSize)) {
        UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation).draw(in: rect)
      }
    }
    return result
  }
}

/// https://stackoverflow.com/a/76474425
extension Image {
  @MainActor
  func getUIImage(newSize: CGSize) -> UIImage? {
    let image = resizable()
      .scaledToFill()
      .frame(width: newSize.width, height: newSize.height)
      .clipped()
    return ImageRenderer(content: image).uiImage
  }
}

// swift-tools-version: 6.2

import PackageDescription

#if TUIST
  import ProjectDescription

  let packageSettings: PackageSettings = .init(
    productTypes: [
      "Anime365Kit": .framework,
      "AppdbFramework": .framework,
      "Collections": .framework,
      "JikanApiClient": .framework,
      "ShikimoriApiClient": .framework,
      "ThirdPartyVideoPlayer": .framework,
    ]
  )
#endif

let package = Package(
  name: "Ichime",
  dependencies: [
    .package(path: "../Packages/Anime365Kit"),
    .package(path: "../Packages/JikanApiClient"),
    .package(path: "../Packages/ShikimoriApiClient"),
    .package(path: "../Packages/ThirdPartyVideoPlayer"),
    .package(url: "https://github.com/appdb-official/AppdbSDK.git", .upToNextMinor(from: "1.6.2")),
    .package(url: "https://github.com/apple/swift-collections.git", .upToNextMinor(from: "1.6.0")),
  ]
)

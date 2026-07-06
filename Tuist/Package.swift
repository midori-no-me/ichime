// swift-tools-version: 6.2

import PackageDescription

#if TUIST
  import ProjectDescription

  let packageSettings: PackageSettings = .init(
    productTypes: [
      "Anime365Kit": .framework,
      "Collections": .framework,
      "DITranquillity": .framework,
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
    .package(url: "https://github.com/apple/swift-collections.git", .upToNextMinor(from: "1.1.4")),
    .package(url: "https://github.com/ivlevAstef/DITranquillity.git", .upToNextMinor(from: "4.5.0")),
  ]
)

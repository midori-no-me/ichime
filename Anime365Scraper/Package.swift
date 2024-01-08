// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Anime365Scraper",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Anime365Scraper",
            targets: ["Anime365Scraper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Anime365Scraper", dependencies: ["SwiftSoup"], path: "Sources"
        ),
        .testTarget(
            name: "Anime365ScraperTests",
            dependencies: ["Anime365Scraper"]
        ),
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AdSurgeADNAdapterForLevelPlay",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "AdSurgeADNAdapterForLevelPlay",
      targets: ["AdSurgeADNAdapterForLevelPlayTarget"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "2.0.2"),
    .package(
      url: "https://github.com/ironsource-mobile/LevelPlay-Swift-Package.git", "9.2.0"..<"99.0.0"),
  ],
  targets: [
    .target(
      name: "AdSurgeADNAdapterForLevelPlayTarget",
      dependencies: [
        .target(name: "AdSurgeADNAdapterForLevelPlay"),
        .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
        .product(name: "UnityMediationSDK", package: "LevelPlay-Swift-Package"),
      ],
      path: "AdSurgeADNAdapterForLevelPlayTarget"
    ),
    .binaryTarget(
      name: "AdSurgeADNAdapterForLevelPlay",
      url:
        "https://github.com/ODCFrontend/adsurge-levelplay-adapter-ios/releases/download/2.0.200/AdSurgeADNAdapterForLevelPlay.zip",
      checksum: "6e1c1dee2ce1ff8c714ef9c6e3473ed88c390202ca4de79a2bb36d2c84b9e57c"
    ),
  ]
)

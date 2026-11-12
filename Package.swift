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
      checksum: "ebbe61673aa2bc5e3bf723eb6827e21ea98681a3be5dc48c6129bb2b85799566"
    ),
  ]
)

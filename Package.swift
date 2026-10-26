// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AdSurgeADNAdapterForLevelPlay",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "AdSurgeADNAdapterForLevelPlay",
      targets: ["AdSurgeADNAdapterForLevelPlay"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "2.0.0"),
    .package(
      url: "https://github.com/ironsource-mobile/LevelPlay-Swift-Package.git", from: "9.3.0"),
  ],
  targets: [
    .target(
      name: "AdSurgeADNAdapterForLevelPlay",
      dependencies: [
        .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
        .product(name: "UnityMediationSDK", package: "LevelPlay-Swift-Package"),
      ],
      path: "AdSurgeADNAdapterForLevelPlay",
      publicHeadersPath: "."
    )
  ]
)

// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CloudinaryKit",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .watchOS(.v9)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "CloudinaryKit",
      targets: ["CloudinaryKit"]
    ),
  ],
  dependencies: [
    .package(name: "PiuPiu", path: "../../")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "CloudinaryKit",
      dependencies: [
        .product(name: "PiuPiu", package: "PiuPiu"),
      ]
    ),
    .testTarget(
      name: "CloudinaryKitTests",
      dependencies: ["CloudinaryKit"]
    ),
  ]
)

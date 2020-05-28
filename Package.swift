// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Caerula",
    platforms: [.iOS(.v9)],
    products: [.library(name: "Caerula", targets: ["Caerula"])],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/banjun/NorthLayout", from: "5.0.0"),
        .package(url: "https://github.com/banjun/ikemen", .branch("spm")),
    ],
    targets: [
        .target(
            name: "Caerula",
            dependencies: ["NorthLayout", .product(name: "Ikemen", package: "ikemen")],
            path: "Caerula/Classes"),
        .testTarget(
            name: "CaerulaTests",
            dependencies: ["Caerula"],
            path: "Example/Tests"),
    ]
)

// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMosquitto",
    products: [
        .library(name: "SwiftMosquitto", targets: ["SwiftMosquitto"]),
        .executable(name: "mosquitto-client", targets: ["mosquitto-client"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rhx/Clibmosquitto.git", .branch("master")),
   ],
    targets: [
        .target(name: "SwiftMosquitto", dependencies: ["Clibmosquitto"]),
        .target(name: "mosquitto-client", dependencies: ["SwiftMosquitto"]),
        .testTarget(name: "SwiftMosquittoTests", dependencies: ["SwiftMosquitto"]),
    ]
)

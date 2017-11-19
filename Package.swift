// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mosquitto",
    products: [
        .library(name: "Mosquitto", targets: ["Mosquitto"]),
        .executable(name: "mosquitto-client", targets: ["mosquitto-client"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rhx/Clibmosquitto.git", .branch("master")),
   ],
    targets: [
        .target(name: "Mosquitto", dependencies: []),
        .target(name: "mosquitto-client", dependencies: ["Mosquitto"]),
        .testTarget(name: "MosquittoTests", dependencies: ["Mosquitto"]),
    ]
)

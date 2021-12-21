// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "Asynchrone",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0")
    ],
    products: [
        .library(
            name: "Asynchrone",
            targets: ["Asynchrone"]
        )
    ],
    targets: [
        .target(
            name: "Asynchrone",
            path: "Asynchrone",
            exclude: ["Supporting Files/Asynchrone.docc"]
        ),
        .testTarget(
            name: "AsynchroneTests",
            dependencies: ["Asynchrone"],
            path: "AsynchroneTests"
        )
    ]
)

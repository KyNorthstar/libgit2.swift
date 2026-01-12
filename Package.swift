// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libgit2.swift",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Git",
            targets: ["Git"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RougeWare/Swift-Safe-Pointer.git", from: "2.1.3"),
        .package(url: "https://github.com/RougeWare/Swift-Either.git", from: "2.0.0"),
        .package(url: "https://github.com/RougeWare/Swift-Lazy-Containers.git", from: "4.1.0"),
        .package(url: "https://github.com/RougeWare/Swift-Optional-Tools.git", from: "1.2.0"),
        .package(url: "https://github.com/RougeWare/Swift-Safe-Collection-Access.git", from: "2.3.0"),
//        .package(url: "https://github.com/RougeWare/Swift-Simple-Logging", from: "0.5.2"),
        .package(url: "https://github.com/RougeWare/Swift-String-Integer-Access", from: "2.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Git",
            dependencies: [
                .product(name: "SafePointer", package: "Swift-Safe-Pointer"),
                .product(name: "Either", package: "Swift-Either"),
                .product(name: "LazyContainers", package: "Swift-Lazy-Containers"),
                .product(name: "OptionalTools", package: "Swift-Optional-Tools"),
                .product(name: "SafeCollectionAccess", package: "Swift-Safe-Collection-Access"),
                .product(name: "SafeStringIntegerAccess", package: "Swift-String-Integer-Access"),
                .product(name: "StringIntegerAccess", package: "Swift-String-Integer-Access"),
//                .product(name: "SimpleLogging", package: "Swift-Simple-Logging"),
            ],
            swiftSettings: [
                .define("GIT_WIN32", .when(platforms: [.windows])),
                .define("DEBUG", .when(configuration: .debug)),
                .define("__OpenBSD__", .when(platforms: [.openbsd])),
            ]),
        .testTarget(
            name: "GitTests",
            dependencies: ["Git"]
        ),
    ]
)



//#if DEBUG
for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(
        .unsafeFlags([
            "-warnings-as-errors",
            "-Xfrontend", "-enable-actor-data-race-checks",
        ])
    )
}
//#endif

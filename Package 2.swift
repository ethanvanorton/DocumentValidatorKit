// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocumentValidatorKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DocumentValidatorKit",
            targets: ["DocumentValidatorKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // The library target compiles code in Sources/DocumentValidatorKit
        .target(
            name: "DocumentValidatorKit",
            path: "Sources/DocumentValidatorKit"
        ),
        // The test target compiles code in Tests/DocumentValidatorKitTests
        .testTarget(
            name: "DocumentValidatorKitTests",
            dependencies: ["DocumentValidatorKit"],
            path: "Tests/DocumentValidatorKitTests"
        ),
    ]
)

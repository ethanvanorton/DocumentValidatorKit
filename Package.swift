// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DocumentValidatorKit",
    
    platforms: [
        .iOS(.v16)
    ],
    
    products: [
        .library(
            name: "DocumentValidatorKit",
            targets: ["DocumentValidatorKit"]
        ),
    ],
    
    targets: [
        .target(
            name: "DocumentValidatorKit",
            resources: [
                .process("DocumentClassifier.mlmodel")
            ]
        ),
        
        .testTarget(
            name: "DocumentValidatorKitTests",
            dependencies: ["DocumentValidatorKit"]
        )
    ]
)

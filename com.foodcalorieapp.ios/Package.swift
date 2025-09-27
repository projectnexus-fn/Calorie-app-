// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodCalorieApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FoodCalorieApp",
            targets: ["FoodCalorieApp"]
        ),
        .library(
            name: "AIEngine",
            targets: ["AIEngine"]
        )
    ],
    dependencies: [
        // Core ML and Vision frameworks are available as system frameworks
        // Add external dependencies here if needed
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FoodCalorieApp",
            dependencies: ["AIEngine"],
            path: "FoodCalorieApp"
        ),
        .target(
            name: "AIEngine",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "AIEngine"
        ),
        .testTarget(
            name: "FoodCalorieAppTests",
            dependencies: ["FoodCalorieApp"]
        ),
        .testTarget(
            name: "AIEngineTests",
            dependencies: ["AIEngine"]
        )
    ]
)
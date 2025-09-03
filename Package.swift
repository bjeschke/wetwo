// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WeTwo",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WeTwo",
            targets: ["WeTwo"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "WeTwo",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "WeTwo"
        )
    ]
)
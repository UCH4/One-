// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LoginSwift",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LoginSwift", targets: ["LoginSwift"]),
        .executable(name: "LoginSwiftApp", targets: ["LoginSwiftApp"])
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0"),
        // Firebase multiplataforma (puente para Android + stubs en iOS)
        .package(url: "https://source.skip.tools/skip-firebase.git", from: "1.0.0"),
        // SDK nativo de Firebase para iOS
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        // Módulo compartido (lógica + ViewModels)
        .target(
            name: "LoginSwift",
            dependencies: [
                .product(name: "SkipFuse", package: "skip-fuse"),
                .product(name: "SkipFirebase", package: "skip-firebase")   // <-- Para poder usar import SkipFirebase
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "SkipStone", package: "skip-fuse")]
        ),
        // Módulo solo iOS (tus vistas SwiftUI y código específico de Darwin)
        .target(
            name: "LoginSwiftApp",
            dependencies: [
                "LoginSwift",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Darwin"
        ),
        .testTarget(
            name: "LoginSwiftTests",
            dependencies: ["LoginSwift"],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "SkipStone", package: "skip-fuse")]
        )
    ]
)

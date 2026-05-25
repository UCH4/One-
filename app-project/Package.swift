// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LoginSwift",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LoginSwift", type: .dynamic, targets: ["LoginSwift"])
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.6.0"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.2"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.5.0"),
        .package(url: "https://source.skip.tools/skip-firebase.git", "0.9.0"..<"2.0.0")
    ],
    targets: [
        .target(name: "LoginSwift", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
            .product(name: "SkipFuse", package: "skip-fuse"),
            .product(name: "SkipModel", package: "skip-model"),
            .product(name: "SkipFirebaseCore", package: "skip-firebase"),       
            .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
            .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
        ], resources: [.process("Resources")],
        plugins: [.plugin(name: "skipstone", package: "skip")]),

        .testTarget(name: "LoginSwiftTests", dependencies: [
            "LoginSwift",
            .product(name: "SkipTest", package: "skip")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)

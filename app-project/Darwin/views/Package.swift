#if false
// This file is a reference template and MUST NOT be compiled as part of the app target.
// It previously contained a SwiftPM manifest (import PackageDescription), which causes
// Xcode to try to compile it as a regular Swift source file inside your app target.
// Keeping it wrapped in `#if false` preserves the reference while preventing build errors.

// If you need a real Package.swift, place a single manifest named exactly `Package.swift`
// at the repository root. Do not keep additional manifests inside source folders.

// Template (for reference only):
// swift-tools-version: 6.1
// import PackageDescription
// let package = Package(
//     name: "LoginSwiftApp",
//     defaultLocalization: "en",
//     platforms: [.iOS(.v17), .macOS(.v14)],
//     products: [ .library(name: "LoginSwift", type: .dynamic, targets: ["LoginSwift"]) ],
//     dependencies: [
//         .package(url: "https://source.skip.tools/skip.git", from: "1.8.18"),
//         .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
//         .package(url: "https://source.skip.tools/skip-firebase.git", from: "1.0.0")
//     ],
//     targets: [
//         .target(
//             name: "LoginSwift",
//             dependencies: [
//                 .product(name: "SkipUI", package: "skip-ui"),
//                 .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
//                 .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
//                 .product(name: "SkipFirebaseAnalytics", package: "skip-firebase")
//             ],
//             resources: [.process("Resources")],
//             plugins: [.plugin(name: "skipstone", package: "skip")]
//         ),
//         .testTarget(
//             name: "LoginSwiftTests",
//             dependencies: [
//                 "LoginSwift",
//                 .product(name: "SkipTest", package: "skip")
//             ],
//             resources: [.process("Resources")],
//             plugins: [.plugin(name: "skipstone", package: "skip")]
//         ),
//     ]
// )
#endif

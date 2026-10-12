// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "MacQuickLookModern", platforms: [.macOS(.v13)], products: [.library(name: "FormatCore", targets: ["FormatCore"])], targets: [.target(name: "FormatCore", path: "Shared"), .testTarget(name: "FormatCoreTests", dependencies: ["FormatCore"], path: "Tests")])

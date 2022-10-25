// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "manifest-cycle-bug",
	platforms: [.macOS(.v11)],
    dependencies: [
        .package(path: "../../swift-project/swiftpm/"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "manifest-cycle-bug",
            dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "SwiftPM-auto", package: "swiftpm"),
			]),
        .testTarget(
            name: "manifest-cycle-bugTests",
            dependencies: ["manifest-cycle-bug"]),
    ]
)

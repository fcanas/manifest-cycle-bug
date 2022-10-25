// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "manifest-cycle-bug",
	platforms: [.macOS(.v11)],
    dependencies: [
//		.package(url: "https://github.com/fcanas/swift-package-manager", branch: "cycles"),
		.package(url: "https://github.com/apple/swift-package-manager", branch: "main"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "manifest-cycle-bug",
            dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "SwiftPM-auto", package: "swift-package-manager"),
			]),
        .testTarget(
            name: "manifest-cycle-bugTests",
            dependencies: ["manifest-cycle-bug"]),
    ]
)

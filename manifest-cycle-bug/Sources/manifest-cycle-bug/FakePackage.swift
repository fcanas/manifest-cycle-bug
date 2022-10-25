//
//  FakePackage.swift
//  
//
//  Created by Fabián Cañas on 10/24/22.
//

import Foundation


struct FakePackage {
	
	internal init(name: String, dependencies: [String]) {
		self.name = FakePackage.Prefix + name
		self.dependencies = dependencies.map({ FakePackage.Prefix + $0 })
	}
	
	internal init(nameNoPrefix: String, dependencies: [String]) {
		self.name = nameNoPrefix
		self.dependencies = dependencies.map({ FakePackage.Prefix + $0 })
	}
	
	static let Prefix = "Fake_"
	
	var name: String
	var dependencies: [String]
	
	func write(to url: URL) {
		let fm = FileManager.default
		let rootURL = url.appendingPathComponent(name, isDirectory: true)
		let sourceURL = url.appendingPathComponent("\(name)/Sources/\(name)", isDirectory: true)
		try! fm.createDirectory(at: sourceURL, withIntermediateDirectories: true)
		
		try! manifest().data(using: .utf8)?.write(to: rootURL.appendingPathComponent("Package.swift"))
		try! source().data(using: .utf8)?.write(to: sourceURL.appendingPathComponent("\(name).swift"))
	}
	
	func source() -> String {
		"""
		\(dependencies.map({ "import \($0)" }).joined(separator: "\n"))
		public struct \(name) {
			public var name: Int = 0
			\(dependencies.map({ "public var _\($0): \($0)" }).joined(separator: "\n"))
		}
		"""
	}
	
	func manifest() -> String {
	"""
	// swift-tools-version: 5.7

	import PackageDescription

	let package = Package(
		name: "\(name)",
		platforms: [.macOS(.v11)],
		products: [
			.library(
				name: "\(name)",
				targets: ["\(name)"]
			),
		],
		dependencies: [
			\(dependencies.map { ".package(path: \"../\($0)\")" }.joined(separator: ", "))
		],
		targets: [
			.target(
				name: "\(name)",
				dependencies: [
					\(dependencies.map { "\"\($0)\"" }.joined(separator: ", "))
				])
		]
	)
	"""
	}
}

	

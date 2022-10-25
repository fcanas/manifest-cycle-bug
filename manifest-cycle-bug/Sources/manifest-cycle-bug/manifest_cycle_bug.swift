import ArgumentParser
import Basics
import Foundation
import TSCBasic
import Workspace

@main
struct ManifestCycleBug: ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Exercises cycle detection in SPM",
		subcommands: [Generate.self, Profile.self, Clean.self]
	)
	
}

struct Options: ParsableArguments {
	@Option(name: .shortAndLong, completion: .directory)
	var location: String = ".."
}

struct GenerateOptions: ParsableArguments {
	@Option(name: .shortAndLong, help: "Adds a number of cycles to the generated manifest tree")
	var cycle: Int = 0
	
	@Argument
	var count: Int = 25
}

struct InfiniteNames: IteratorProtocol {
	
	private var prefix: String = ""
	private var current: UnicodeScalar = "Z"
	
	mutating func next() -> String? {
		if current == "Z" {
			prefix.append("_")
			current = "A"
		} else {
			current = UnicodeScalar(current.value + 1)!
		}
		return prefix + String(current)
	}
	
	typealias Element = String
}

struct Generate: ParsableCommand {
	
	@OptionGroup
	var options: Options
	
	@OptionGroup
	var generateOptions: GenerateOptions
	
	func run() throws {
		try Clean(options: _options).run()
		
		let rootURL = URL(fileURLWithPath: options.location)
		var names = InfiniteNames()
		
		guard generateOptions.count > 1 else {
			fatalError("Generated package count must be at least 2")
		}
		
		print("Generating \(generateOptions.count) projects with \(generateOptions.cycle) cycle\(generateOptions.cycle == 1 ? "" : "s")…")
		
		var accumulatedNames: [String] = []
		
		for _ in 1..<generateOptions.count {
			let name = names.next()!
			FakePackage(name: name, dependencies: accumulatedNames).write(to: rootURL)
			accumulatedNames.append(name)
		}
		
		let cycles: Int
		if generateOptions.cycle > (generateOptions.count - 2) {
			cycles = generateOptions.count - 2
			print("Cycle generation isn't at all sophisticated. Capping number of cycles to \(cycles)")
		} else {
			cycles = generateOptions.cycle
		}
		for cycleIndex in 0..<cycles {
			let cycleName = accumulatedNames[cycleIndex]
			let deps: Array<String> = accumulatedNames[..<cycleIndex] + [accumulatedNames.last!]
			FakePackage(name: cycleName, dependencies: deps).write(to: rootURL)
		}
		
		FakePackage(nameNoPrefix: "Apex", dependencies: [accumulatedNames.last].compactMap({$0})).write(to: rootURL)
		
		print("Done.")
		print("Open Apex project at \(rootURL.appendingPathComponent("Apex").absoluteURL.path)")
	}
}

struct Clean: ParsableCommand {
	
	@OptionGroup
	var options: Options
	
	func run() throws {
		print("Cleaning…")
		
		let rootURL = URL(fileURLWithPath: options.location)
		let fm = FileManager.default
		try! fm.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles).forEach { url in
			if
				url.lastPathComponent.hasPrefix(FakePackage.Prefix),
				let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
				isDirectory
			{
				try fm.removeItem(at: url)
			} else {
				if url.lastPathComponent == "Apex" {
					try fm.removeItem(at: url)
				}
			}
			
		}

	}
}

struct Profile: ParsableCommand {
	@OptionGroup
	var options: Options
	
	@OptionGroup
	var generateOptions: GenerateOptions
	
	@Flag(name: .shortAndLong, help: "Print output of SPM Observability system.")
	var verbose: Bool = false
	
	func run() throws {
		
		try Generate(options: _options, generateOptions: _generateOptions).run()
			
		let rootURL = URL(fileURLWithPath: options.location).absoluteURL.appendingPathComponent("Apex", isDirectory: true)
		let path = try AbsolutePath(validating: rootURL.path)
		let workspace = try! Workspace(forRootPackage: path)
		let observability = ObservabilitySystem { scope, diag in
			if verbose || diag.severity == .error {
				print("\(scope)\(diag)")
			}
		}
		var foundCycle = false
		let startTime = Date()
		do {
			_ = try workspace.loadPackageGraph(rootPath: path, observabilityScope: observability.topScope)
		} catch GraphError.unexpectedCycle {
			if generateOptions.cycle > 0 {
				foundCycle = true
				print("✅ Caught an expected cycle.")
			}
		}
		if generateOptions.cycle > 0 && foundCycle == false {
			print("❌ Failed to catch a cycle. Not good.")
		}
		
		let interval = Date().timeIntervalSince(startTime)
		print("Loaded package graph in \(String(format: "%.1fs", interval)) seconds.")
	
	}
	
}

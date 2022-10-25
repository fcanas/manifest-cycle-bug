# manifest-cycle-bug

This tool generates a tree of SPM dependencies, and profiles loading them with
`Workspace.loadPackageGraph(rootPath:...)`, which Xcode uses. This eventually
calls into [`findCycle()`](https://github.com/apple/swift-package-manager/blob/25c671ef3ef2bd7a245403f9848cb3be3321c790/Sources/PackageGraph/PackageGraph%2BLoading.swift#L866), which has a bug leading to quadratic-time cycle
detection.

A fork of SPM adding memoization to [`findCycle`](https://github.com/fcanas/swift-package-manager/blob/baae4bb996ab810012f21107f0025aa073cbc4b1/Sources/PackageGraph/PackageGraph%2BLoading.swift#L866) 
can be swapped in this repository's `Package.swift` to show the impact.

| Number of packages | apple/spm | memoized |
|--------------------|-----------|----------|
| 22                 | 17.9s     | 0.2s     |
| 23                 | 35.8s     | 0.2s     |
| 24                 | 88.1s     | 0.2s     |
| 25                 | 160.5s    | 0.2s     |
| 26                 | 323.4s    | 0.2s     |

Edit `Package.swift` to switch SPM implementations.

```
    dependencies: [
        //.package(path: "../../swift-project/swiftpm/"),
		//.package(url: "https://github.com/fcanas/swift-package-manager", branch: "canon"),
		.package(url: "https://github.com/apple/swift-package-manager", branch: "main"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
```

`.package(url: "https://github.com/apple/swift-package-manager", branch: "main")` will exhibit quadratic time loading manifests.

`.package(url: "https://github.com/fcanas/swift-package-manager", branch: "canon")` will be linear, and noticably faster with large package graphs.

## Running the tool

Note that this repository puts the tool's root one directory in. That's because
the tool will generate a tree of SPM packages on disk with the default location
`..`. So running the tool from inside its package directory will generate a tree
safely in the confines of the repository. The location can be specified with
`-l`.
 
```
USAGE: manifest-cycle-bug profile [--location <location>] [--cycle <cycle>] [<count>] [--verbose]

ARGUMENTS:
  <count>                 (default: 25)

OPTIONS:
  -l, --location <location>
                          (default: ..)
  -c, --cycle <cycle>     Adds a number of cycles to the generated manifest tree (default: 0)
  -v, --verbose           Print output of SPM Observability system.
  -h, --help              Show help information.
```

There are two other subcommands. `clean` removes generated packages. `generate`
will run `clean` and generate the package tree without profiling. `profile` runs
both `clean` and `generate`.

Profiling a package tree with 22 manifests like this.

```
swift run manifest-cycle-bug profile 22
```

The tool also allows introducing cycles to help show things still work with
memoization.

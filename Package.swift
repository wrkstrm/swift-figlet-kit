// swift-tools-version:6.2
import Foundation
import PackageDescription

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return false }
  let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return v == "1" || v == "true" || v == "yes"
}()

func localOrRemote(
  name: String, path: String, url: String, requirement: Package.Dependency.Requirement
) -> Package.Dependency {
  if useLocalDeps { return .package(name: name, path: path) }
  return .package(url: url, requirement)
}

let package: Package = .init(
  name: "SwiftFigletKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "SwiftFigletKit", targets: ["SwiftFigletKit"]),
    .executable(name: "swift-figlet-cli", targets: ["SwiftFigletCLI"]),
    .executable(name: "swift-figlet-doc-gen", targets: ["SwiftFigletDocGen"]),
    .executable(name: "swift-figlet-dedupe", targets: ["SwiftFigletDedupe"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    // DocC plugin enables `swift package generate-documentation`
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    localOrRemote(
      name: "common-shell",
      path: "../../../common/domain/system/common-shell",
      url: "https://github.com/wrkstrm/common-shell.git",
      requirement: .upToNextMajor(from: "0.1.0")),
  ],
  targets: [
    .systemLibrary(
      name: "CZlib",
      pkgConfig: nil,
      providers: [
        .brew(["zlib"]),
        .apt(["zlib1g-dev"]),
      ]
    ),
    .target(
      name: "SwiftFigletKit",
      dependencies: ["CZlib"],
      resources: [
        .copy("Resources/Fonts")
      ],
      swiftSettings: [
        .define("SIMULATOR", .when(platforms: [.iOS], configuration: .debug))
      ],
    ),
    .executableTarget(
      name: "SwiftFigletDedupe",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
    ),
    .executableTarget(
      name: "SwiftFigletDocGen",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
    ),
    .executableTarget(
      name: "SwiftFigletCLI",
      dependencies: [
        "SwiftFigletKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "CommonShell", package: "common-shell"),
      ],
    ),
    .testTarget(
      name: "SwiftFigletKitTests",
      dependencies: ["SwiftFigletKit"],
      resources: [
        .copy("testFonts")
      ],
    ),
  ],
)

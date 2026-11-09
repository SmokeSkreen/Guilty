// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Guilty", platforms: [.macOS(.v13)], products: [.executable(name: "Guilty", targets: ["Guilty"])], targets: [.executableTarget(name: "Guilty"), .testTarget(name: "GuiltyTests", dependencies: ["Guilty"])])

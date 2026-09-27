// swift-tools-version:5.5.0
import PackageDescription
let package = Package(
	name: "Taskchampion",
	products: [
		.library(
			name: "Taskchampion",
			targets: ["Taskchampion"]),
	],
	dependencies: [],
	targets: [
		.binaryTarget(
			name: "RustXcframework",
			path: "RustXcframework.xcframework"
		),
		.target(
			name: "Taskchampion",
			dependencies: ["RustXcframework"])
	]
)
	
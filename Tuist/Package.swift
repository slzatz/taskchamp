// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "MarkdownUI": .framework // default is .staticFramework
    ],
    // Xcode 27 rejects iOS deployment targets below 15; several packages still declare 12/14.
    targetSettings: [
        "Taskchampion": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]),
        "cmark-gfm": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]),
        "cmark-gfm-extensions": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]),
        "NetworkImage": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]),
        "MarkdownUI": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"])
    ]
)
#endif

let package = Package(
    name: "taskchamp",
    dependencies: [
        // Add your own dependencies here:
        Package.Dependency.package(url: "https://github.com/soulverteam/SoulverCore", from: "2.6.3"),
        Package.Dependency.package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        Package.Dependency.package(
            name: "Taskchampion",
            path: "../task-champion-swift/taskchampion-swift/taskchampion-swift/"
        )
    ]
)

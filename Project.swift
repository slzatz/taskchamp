import ProjectDescription

/// Apple Developer team used for automatic code signing (Membership details on developer.apple.com).
let developmentTeam = "LAH24RFYPW"

let project = Project(
    name: "taskchamp",
    settings: .settings(base: [
        "SWIFT_OBJC_INTEROP_MODE": "objcxx",
        "SWIFT_INCLUDE_PATHS": ["$(PROJECT_DIR)"],
        "DEVELOPMENT_TEAM": .string(developmentTeam),
        "CODE_SIGN_STYLE": "Automatic",
        // The Rust bridge is only built for arm64 simulators; without this, Release simulator
        // builds (the scheme's Run action) also try to link x86_64 and fail.
        "EXCLUDED_ARCHS[sdk=iphonesimulator*]": "x86_64"
    ], defaultSettings: .recommended),
    targets: [
        .target(
            name: "taskchamp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.slzatz.taskchamp",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "Taskchamp",
                    "CFBundleDisplayName": "Taskchamp Dev",
                    "UILaunchScreen": [
                        "UIColorName": "LaunchBackground"
                    ],
                    "NSAccentColorName": "AccentColor",
                    "ITSAppUsesNonExemptEncryption": false,
                    "CFBundleShortVersionString": "3.7",
                    // VimNotes' task notes link back with taskchampdev://task/<uuid>.
                    // Not taskchamp://, which the App Store Taskchamp claims.
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "com.slzatz.taskchamp",
                            "CFBundleURLSchemes": ["taskchampdev"]
                        ]
                    ]
                ]
            ),
            sources: ["taskchamp/Sources/**"],
            resources: ["taskchamp/Resources/**"],
            entitlements: .dictionary(
                [
                    "com.apple.developer.usernotifications.time-sensitive": true,
                    "com.apple.security.application-groups": ["group.com.slzatz.taskchamp"]
                ]
            ),
            scripts: [
                .pre(script: "./scripts/pre_build_script.sh", name: "Prebuild", basedOnDependencyAnalysis: false)
            ],
            dependencies: [
                .external(name: "MarkdownUI"),
                .target(name: "taskchampShared"),
                .target(name: "taskchampWidget"),
                .target(name: "taskchampShareExtension")
            ],
            settings: .settings(base: [
                // Shows the DEV badge in the task list header. Remove to hide it.
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) TASKCHAMP_DEV"
            ])
        ),
        .target(
            name: "taskchampTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.slzatz.taskchampTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["taskchamp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "taskchamp")]
        ),
        .target(
            name: "taskchampWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.slzatz.taskchamp.taskchampWidget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "$(PRODUCT_NAME)",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ],
                "CFBundleShortVersionString": "3.7"
            ]),
            sources: "taskchampWidget/Sources/**",
            entitlements: .dictionary(
                [
                    "com.apple.security.application-groups": ["group.com.slzatz.taskchamp"]
                ]
            ),
            dependencies: [
                .target(name: "taskchampShared")
            ]
        ),
        .target(
            name: "taskchampShareExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.slzatz.taskchamp.taskchampShareExtension",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Taskchamp Dev",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.share-services",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ShareViewController",
                    "NSExtensionAttributes": [
                        "NSExtensionActivationRule": [
                            "NSExtensionActivationSupportsText": true,
                            "NSExtensionActivationSupportsWebURLWithMaxCount": 1,
                            "NSExtensionActivationSupportsWebPageWithMaxCount": 1
                        ]
                    ]
                ],
                "CFBundleShortVersionString": "3.7"
            ]),
            sources: "taskchampShareExtension/Sources/**",
            entitlements: .dictionary([
                "com.apple.security.application-groups": ["group.com.slzatz.taskchamp"]
            ]),
            dependencies: [
                .target(name: "taskchampShared")
            ]
        ),
        .target(
            name: "taskchampShared",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.slzatz.taskchamp.taskchampShared",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: "taskchampShared/Sources/**",
            dependencies: [
                .external(name: "SoulverCore"),
                .external(name: "Taskchampion")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "taskchamp",
            buildAction: .buildAction(targets: ["taskchamp"]),
            testAction: .targets(["taskchampTests"]),
            runAction: .runAction(
                configuration: .release,
                executable: .target("taskchamp")
            )
        )
    ]
)

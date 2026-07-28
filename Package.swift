// swift-tools-version: 6.0

import PackageDescription

#if canImport(AppleProductTypes)
import AppleProductTypes
#endif

#if canImport(AppleProductTypes)
let supportedPlatforms: [SupportedPlatform] = [
    .iOS("16.0")
]

let packageProducts: [Product] = [
    .iOSApplication(
        name: "SteadyTap",
        targets: ["AppModule"],
        bundleIdentifier: "com.kim.steadytap",
        teamIdentifier: "",
        displayVersion: "1.0",
        bundleVersion: "1",
        appIcon: .asset("AppIcon"),
        accentColor: .presetColor(.teal),
        supportedDeviceFamilies: [
            .pad,
            .phone
        ],
        supportedInterfaceOrientations: [
            .portrait,
            .landscapeRight,
            .landscapeLeft,
            .portraitUpsideDown(.when(deviceFamilies: [.pad]))
        ],
        appCategory: "public.app-category.utilities",
        additionalInfoPlistContentFilePath: "Resources/AdditionalInfo.plist"
    )
]
#else
let supportedPlatforms: [SupportedPlatform] = [
    .macOS("14.0")
]

let packageProducts: [Product] = [
    .executable(
        name: "SteadyTap",
        targets: ["AppModule"]
    )
]
#endif

let package = Package(
    name: "SteadyTap",
    platforms: supportedPlatforms,
    products: packageProducts,
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: [
                "backend",
                "app-store",
                "docs",
                "site",
                "scripts",
                "Tests",
                "Verification",
                "CONTRIBUTING.md",
                "LICENSE",
                "Makefile",
                "project.yml",
                "README.md",
                "SECURITY.md",
                "SUPPORT.md",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "SteadyTapTests",
            path: "Tests",
            exclude: [
                "quick_start_content_regression.swift",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ],
    swiftLanguageModes: [.v6]
)

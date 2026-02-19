// swift-tools-version: 6.0

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "SteadyTap",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "SteadyTap",
            targets: ["AppModule"],
            bundleIdentifier: "com.kim.steadytap",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .heart),
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
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ],
    swiftLanguageVersions: [.v6]
)

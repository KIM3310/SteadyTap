import Foundation

enum DistributionPolicy {
    #if DEBUG
    static let allowsDeveloperCloudFeatures = true
    static let showsDeveloperTools = true
    #else
    static let allowsDeveloperCloudFeatures = false
    static let showsDeveloperTools = false
    #endif

    static let privacyPolicyURL = URL(string: "https://steadytap.pages.dev/privacy/")!
    static let supportURL = URL(string: "https://steadytap.pages.dev/support/")!
}

import Foundation

/// Constants shared between the Runner app target and every extension target
/// (ScreenTimeExtension, ShieldConfigurationExtension, ShieldActionExtension).
/// Add this same file to ALL of their target memberships in Xcode — see
/// README.md for why an App Group is required for them to talk to each other
/// at all.
enum ScreenGuardShared {
    // Replace with your own reverse-DNS App Group id, and create the matching
    // App Group in Apple Developer > Identifiers, then enable it on both targets.
    static let appGroupId = "group.com.screenguard.app"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    enum Keys {
        static let selectionData = "familyActivitySelectionData"
        static let selectionLimitMinutes = "selectionLimitMinutes"
        static let selectionWarnBeforeMinutes = "selectionWarnBeforeMinutes"
        static let totalLimitMinutes = "totalLimitMinutes"
        static let totalWarnBeforeMinutes = "totalWarnBeforeMinutes"
        static let blockMessage = "blockMessage"
        static let pendingBlockReason = "pendingBlockReason"
        static let lastUnblockMillis = "lastUnblockMillis"
        static let reblockCooldownMinutes = "reblockCooldownMinutes"
    }

    static let selectionLimitEventName = "screenguard.selectionLimit"
    static let totalLimitEventName = "screenguard.totalLimit"
    static let activityName = "screenguard.daily"
}

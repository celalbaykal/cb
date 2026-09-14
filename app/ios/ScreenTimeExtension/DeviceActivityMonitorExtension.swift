import DeviceActivity
import FamilyControls
import ManagedSettings
import UserNotifications

// This file belongs to a separate "ScreenTimeExtension" Xcode target of type
// Device Activity Monitor Extension — Xcode's New Target wizard must create
// that target; this source can't create it. See README.md for the exact
// steps (App Group, entitlement, embedding this into Runner).
//
// NOTE: ManagedSettings/DeviceActivity's exact API shape has shifted across
// iOS SDK versions. Build this against the Xcode version you're targeting
// and adjust signatures if the compiler flags a mismatch — this is written
// against the iOS 16+ shape documented by Apple.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard activity.rawValue == ScreenGuardShared.activityName else { return }
        guard event.rawValue == ScreenGuardShared.selectionLimitEventName
            || event.rawValue == ScreenGuardShared.totalLimitEventName
        else { return }

        guard let data = ScreenGuardShared.defaults.data(forKey: ScreenGuardShared.Keys.selectionData),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: Set())

        ScreenGuardShared.defaults.set("total", forKey: ScreenGuardShared.Keys.pendingBlockReason)
        postLocalNotification()
    }

    private func postLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time's up"
        content.body = "You reached today's screen time limit. Open ScreenGuard to continue."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

/// Wraps Apple's Screen Time API (FamilyControls / DeviceActivity /
/// ManagedSettings) — the only mechanism Apple allows a third-party app to
/// use to monitor and shield other apps. Everything here needs:
///   1. The free "Family Controls" entitlement, requested from Apple and
///      added to Runner.entitlements (approval is not instant).
///   2. An App Group shared with the ScreenTimeExtension target.
///   3. The ScreenTimeExtension target itself (DeviceActivityMonitor +
///      ShieldConfiguration), created by hand in Xcode — see README.md.
/// None of this can be exercised in a plain `flutter run` without those
/// pieces in place first.
@available(iOS 16.0, *)
final class ScreenTimeManager: NSObject {
    static let shared = ScreenTimeManager()

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var currentSelection = FamilyActivitySelection()

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasUsagePermission":
            result(AuthorizationCenter.shared.authorizationStatus == .approved)

        case "requestUsagePermission":
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                } catch {
                    // Authorization can be denied or unavailable (e.g. entitlement
                    // not yet approved); the UI just re-checks status afterwards.
                }
                result(nil)
            }

        case "hasAccessibilityPermission":
            // No equivalent concept on iOS.
            result(true)

        case "openAccessibilitySettings":
            result(nil)

        case "getInstalledApps":
            // Apple never exposes the installed-app list to third-party code.
            result([])

        case "pickMonitoredApps":
            presentPicker { result(nil) }

        case "syncMonitoredApps":
            guard let args = call.arguments as? [String: Any],
                  let apps = args["apps"] as? [[String: Any]],
                  let totalLimit = args["totalDailyLimitMinutes"] as? Int,
                  let totalWarn = args["totalWarnBeforeMinutes"] as? Int
            else {
                result(FlutterError(code: "bad_args", message: "Missing arguments", details: nil))
                return
            }
            if let blockMessage = args["blockMessage"] as? String {
                ScreenGuardShared.defaults.set(blockMessage, forKey: ScreenGuardShared.Keys.blockMessage)
            }
            // Only one selection exists on iOS (see ScreenGuardShared), so we
            // use the first tracked-app entry as that selection's own limit.
            let selectionLimit = apps.first?["dailyLimitMinutes"] as? Int ?? totalLimit
            let selectionWarn = apps.first?["warnBeforeMinutes"] as? Int ?? totalWarn
            syncLimitsAndStartMonitoring(
                selectionLimitMinutes: selectionLimit,
                selectionWarnBeforeMinutes: selectionWarn,
                totalLimitMinutes: totalLimit,
                totalWarnBeforeMinutes: totalWarn
            )
            result(nil)

        case "getTodayUsage":
            // Apple does not expose per-app usage minutes to third-party code,
            // only "a threshold was crossed" events inside the extension. We
            // can only report whether a block is currently shielding apps.
            let blocked = ScreenGuardShared.defaults.string(forKey: ScreenGuardShared.Keys.pendingBlockReason) != nil
            result(["minutesByPackage": [String: Int](), "totalMinutes": blocked ? -1 : 0])

        case "consumePendingBlockReason":
            let defaults = ScreenGuardShared.defaults
            let reason = defaults.string(forKey: ScreenGuardShared.Keys.pendingBlockReason)
            defaults.removeObject(forKey: ScreenGuardShared.Keys.pendingBlockReason)
            result(reason)

        case "acknowledgeBlock":
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            ScreenGuardShared.defaults.set(
                Date().timeIntervalSince1970 * 1000,
                forKey: ScreenGuardShared.Keys.lastUnblockMillis
            )
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func presentPicker(completion: @escaping () -> Void) {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController
        else {
            completion()
            return
        }
        let pickerView = ActivityPickerView(selection: currentSelection) { selection in
            self.currentSelection = selection
            if let data = try? JSONEncoder().encode(selection) {
                ScreenGuardShared.defaults.set(data, forKey: ScreenGuardShared.Keys.selectionData)
            }
            rootVC.dismiss(animated: true, completion: completion)
        }
        let hosting = UIHostingController(rootView: pickerView)
        rootVC.present(hosting, animated: true)
    }

    private func syncLimitsAndStartMonitoring(
        selectionLimitMinutes: Int,
        selectionWarnBeforeMinutes: Int,
        totalLimitMinutes: Int,
        totalWarnBeforeMinutes: Int
    ) {
        let defaults = ScreenGuardShared.defaults
        defaults.set(selectionLimitMinutes, forKey: ScreenGuardShared.Keys.selectionLimitMinutes)
        defaults.set(selectionWarnBeforeMinutes, forKey: ScreenGuardShared.Keys.selectionWarnBeforeMinutes)
        defaults.set(totalLimitMinutes, forKey: ScreenGuardShared.Keys.totalLimitMinutes)
        defaults.set(totalWarnBeforeMinutes, forKey: ScreenGuardShared.Keys.totalWarnBeforeMinutes)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let selectionEvent = DeviceActivityEvent(
            applications: currentSelection.applicationTokens,
            categories: currentSelection.categoryTokens,
            threshold: DateComponents(minute: selectionLimitMinutes)
        )
        let totalEvent = DeviceActivityEvent(
            applications: currentSelection.applicationTokens,
            categories: currentSelection.categoryTokens,
            threshold: DateComponents(minute: totalLimitMinutes)
        )

        let activityName = DeviceActivityName(rawValue: ScreenGuardShared.activityName)
        center.stopMonitoring([activityName])
        try? center.startMonitoring(
            activityName,
            during: schedule,
            events: [
                DeviceActivityEvent.Name(rawValue: ScreenGuardShared.selectionLimitEventName): selectionEvent,
                DeviceActivityEvent.Name(rawValue: ScreenGuardShared.totalLimitEventName): totalEvent,
            ]
        )
    }
}

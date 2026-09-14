import ManagedSettings
import UIKit

// Separate Xcode target: "Shield Action Extension" (New Target wizard).
// Handles taps on the shield's button. Apple's shield UI can only show
// static text, not a text field, so the actual "retype your message to
// unlock" flow lives in the Flutter app's BlockScreen — this extension's
// only job is to close the shield and send the user back to their
// Home Screen so they can open ScreenGuard themselves.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        default:
            completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        default:
            completionHandler(.none)
        }
    }
}

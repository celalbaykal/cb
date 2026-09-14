import ManagedSettings
import ManagedSettingsUI
import UIKit

// Separate Xcode target: "Shield Configuration Extension" (New Target
// wizard). Renders the actual full-screen shield Apple shows over a blocked
// app — this is the only place on iOS a custom message can appear natively,
// since Apple (not us) draws the real block screen. See README.md.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: ApplicationToken) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding application: ApplicationToken,
        in category: ActivityCategoryToken
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let message = ScreenGuardShared.defaults.string(forKey: ScreenGuardShared.Keys.blockMessage)
            ?? "Time's up for today."
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            title: ShieldConfiguration.Label(text: "Time's up", color: .white),
            subtitle: ShieldConfiguration.Label(text: message, color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open ScreenGuard", color: .white),
            primaryButtonBackgroundColor: .systemIndigo
        )
    }
}

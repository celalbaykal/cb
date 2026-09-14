import FamilyControls
import SwiftUI

/// Thin SwiftUI wrapper so Apple's FamilyActivityPicker (a SwiftUI-only view)
/// can be presented from UIKit via UIHostingController. Apple owns this UI
/// entirely — the identities of whatever the user picks are never exposed
/// back to app code, only opaque tokens usable for shielding/monitoring.
@available(iOS 16.0, *)
struct ActivityPickerView: View {
    @State private var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void

    init(selection: FamilyActivitySelection, onDone: @escaping (FamilyActivitySelection) -> Void) {
        _selection = State(initialValue: selection)
        self.onDone = onDone
    }

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Choose apps to limit")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onDone(selection) }
                    }
                }
        }
    }
}

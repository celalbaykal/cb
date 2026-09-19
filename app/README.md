# ScreenGuard

A screen time tracker: per-app daily limits, a total daily limit, and a
full-screen block once you hit it that only clears when you retype the
personal message you wrote for yourself. Everything is stored on-device —
no account, no server. A banner ad slot at the bottom of the home screen is
wired up with Google AdMob's test ad unit, ready to swap for a real one.

## Quick start (Android)

The Android side is fully generated, merged, and verified already — the
native Gradle project (`android/`) was produced by a real `flutter create`
run and the custom Kotlin/manifest files from this repo were merged into
it, `flutter pub get` resolved cleanly, `flutter analyze` reports no issues,
and the real launcher icon is baked into every `mipmap-*` density. Nothing
to hand-assemble for Android — just:

```bash
git clone https://github.com/celalbaykal/cb.git
cd cb
git checkout claude/phone-screentime-tracker-gbnec4
cd app
flutter pub get
flutter run   # pick your connected Android device/emulator from the list
```

That installs and launches the real app. First launch takes you to the
onboarding screen to grant Usage Access and enable the Accessibility
service; from there, everything — adding apps, setting limits, the block
screen — is exercised in the app itself.

One thing I could not do in this sandbox: actually compile it (no Android
SDK/build-tools/emulator here, only Flutter's own tooling and a Dart
analyzer). `flutter pub get` and `flutter analyze` both came back clean, so
the Dart side is checked; the Kotlin native side has never been compiled,
so treat first build as the real first test of it.

## What's still manual

Everything below is the parts that couldn't be pre-generated: iOS (which
needs Xcode, an Apple entitlement, and manual extension targets — see the
Android quick start above and skip straight to it if that's all you need
right now), AdMob's real ad unit swap, and re-theming the icon.

### Android permissions the user has to grant by hand

Both are "special" permissions Android deliberately keeps out of the normal
runtime-permission dialog, so the app can only deep-link to the right
settings screen and ask the user to flip them on:

- **Usage access** (`Settings.ACTION_USAGE_ACCESS_SETTINGS`) — lets the app
  read today's per-app usage.
- **Accessibility service** (`Settings.ACTION_ACCESSIBILITY_SETTINGS`) —
  lets `AppMonitorAccessibilityService` notice which app is in the
  foreground and act the moment a limit is hit, even if ScreenGuard itself
  isn't open. It only reads window-change events (which package/app is
  frontmost); `canRetrieveWindowContent` is off, so it never reads what's
  on screen.

The onboarding screen walks the user through both and rechecks status when
they come back from Settings.

### How Android enforcement actually works

- `UsageStatsHelper.getUsageForToday()` computes today's per-app minutes
  live from `UsageStatsManager`'s raw foreground/background events — no
  separate bookkeeping to keep in sync or reset at midnight.
- `AppMonitorAccessibilityService` runs independently of the Flutter
  isolate (Android keeps enabled accessibility services alive), checking
  those totals against `MonitorConfigStore`'s limits every ~20s and on every
  foreground-app change.
- Hitting a per-app limit while that app is frontmost sends the user Home
  (`GLOBAL_ACTION_HOME`) and posts a notification.
- Hitting the total daily limit sends the user Home **and** relaunches
  `MainActivity` with a "pending block" flag in `SharedPreferences`; Flutter
  picks that up via `consumePendingBlockReason()` on resume and pushes the
  full-screen `BlockScreen`, which only clears once the user retypes their
  message and calls `acknowledgeBlock()`.
- A low-priority ongoing notification shows today's running total — visible
  on the lock screen without needing any special "show over lock screen"
  permission.

## iOS — read this before starting, it's a bigger lift than Android

Unlike Android above, iOS was **not** run through `flutter create` here —
only the custom Swift files exist so far (`ios/Runner/*.swift`, the
extension folders); there's no Xcode project yet. Start with:

```bash
flutter create --platforms=ios --org com.screenguard --project-name screenguard .
```

then delete the `AppDelegate.swift` it generates (ours in `ios/Runner/` is
the one to keep), and flip `ios: true` back on in `pubspec.yaml`'s
`flutter_launcher_icons` block (it's `false` right now specifically because
that Xcode project didn't exist yet) before rerunning
`dart run flutter_launcher_icons`.

Apple does not let any third-party app read another app's usage or force it
closed the way Android's Accessibility API allows. The **only** sanctioned
mechanism is Apple's own Screen Time API (`FamilyControls` / `DeviceActivity`
/ `ManagedSettings`), which is what `ios/` here is built on. Using it
requires, beyond what any other Flutter feature needs:

1. **A free entitlement request to Apple.** Go to
   <https://developer.apple.com/contact/request/family-controls-distribution>,
   request the "Family Controls" entitlement for your App ID, and wait for
   approval — it is not instant and isn't guaranteed. Nothing Screen-Time
   related will work on a real device (only the iOS Simulator lets you
   partially test the picker/authorization UI) until this is approved.
2. **Three small Xcode extension targets that only Xcode can create** —
   its New Target wizard writes project/entitlement wiring that can't be
   hand-authored as plain text reliably. The Swift source for each is
   already in this repo; you're creating an empty target and pointing it at
   an existing file, not writing new code:

   | New Target type (Xcode's target picker) | Target name | Add these files to it |
   |---|---|---|
   | Device Activity Monitor Extension | `ScreenTimeExtension` | `ios/ScreenTimeExtension/DeviceActivityMonitorExtension.swift`, its `Info.plist`, its `.entitlements`, and `ios/Runner/ScreenGuardShared.swift` |
   | Shield Configuration Extension | `ShieldConfigurationExtension` | `ios/ShieldConfigurationExtension/ShieldConfigurationExtension.swift`, its `Info.plist`, its `.entitlements`, and `ScreenGuardShared.swift` |
   | Shield Action Extension | `ShieldActionExtension` | `ios/ShieldActionExtension/ShieldActionExtension.swift`, its `Info.plist`, its `.entitlements` |

   After adding each target, in its **Signing & Capabilities** tab: add the
   "App Groups" capability and check `group.com.screenguard.app` (create
   that App Group under your Apple Developer account's Identifiers first),
   and for `ScreenTimeExtension`/`ShieldActionExtension` also add the
   "Family Controls" capability. Also add `ios/Runner/Runner.entitlements`'s
   two entries (App Group + Family Controls) to the main `Runner` target the
   same way.
3. Add `ios/Runner/AppDelegate.swift`, `ScreenTimeManager.swift`,
   `ActivityPickerView.swift`, and `ScreenGuardShared.swift` to the `Runner`
   target (delete the `AppDelegate.swift` `flutter create` generated first).

Apple's SDK for these frameworks has shifted in small ways release to
release; the code here follows the iOS 16+ shape Apple documents, but if
Xcode flags a signature mismatch when you build, check that call against
the SDK version you're compiling with — I could not compile this myself in
this environment to catch that in advance.

### What iOS can and can't do, honestly

- **No installed-app list, no per-app usage numbers.** Apple never exposes
  either to third-party code. Choosing apps to limit happens entirely
  through Apple's own `FamilyActivityPicker`, and only opaque tokens come
  back — never a name your code can display. The Home screen's "today"
  total is best-effort on iOS for this reason (see the note it shows there).
- **One shared selection, not independently named per-app limits.** Because
  Apple hides which apps you picked, ScreenGuard can't show "Instagram: 20m
  used" the way it does on Android — it applies the limit you set to
  whatever you selected, as one group.
- **The retype-to-unlock screen is drawn by Apple, not by us, while an app
  is shielded.** `ShieldConfigurationExtension` sets the title/message
  (from the `blockMessage` you set in Settings) on Apple's native shield,
  but that shield can only show static text and one button — there's no
  text field there. So the button (handled by `ShieldActionExtension`)
  just closes the shield and sends the user Home; they then reopen
  ScreenGuard themselves, where the real "retype your message" screen
  (`BlockScreen`, same Flutter code as Android) is shown, and confirming it
  clears the shield via `acknowledgeBlock()`.

## AdMob

`lib/widgets/ad_banner.dart` uses Google's published **test** ad unit IDs
(`ca-app-pub-3940256099942544/...`) and the manifest carries Google's
published **test** Application ID — both are meant to be public and used
during development; they always serve a placeholder ad and never earn
money.

Before releasing:

1. Create an app in your own AdMob account, get a real Application ID and
   banner ad unit ID.
2. Replace the `com.google.android.gms.ads.APPLICATION_ID` value in
   `android/app/src/main/AndroidManifest.xml`.
3. Replace `_testBannerUnitIdAndroid` / `_testBannerUnitIdIOS` in
   `lib/widgets/ad_banner.dart`.
4. For iOS, also add `GADApplicationIdentifier` to `ios/Runner/Info.plist`
   (a key `flutter create` didn't add since AdMob wasn't part of the base
   template) — see AdMob's Flutter quickstart for the exact key.

## App icon

`assets/icon/` has three source images (a modern indigo-gradient hourglass
mark, matching the in-app theme). Android's real launcher icon is already
generated and committed (`android/app/src/main/res/mipmap-*/`, plus the
adaptive-icon background/foreground layers) — nothing to do there. iOS's
`AppIcon.appiconset` doesn't exist until you've run `flutter create
--platforms=ios` (see the iOS section above); once it does, flip `ios: true`
in `pubspec.yaml`'s `flutter_launcher_icons` block and rerun
`dart run flutter_launcher_icons`.

To change the color or redraw the mark, edit `TOP_COLOR`/`BOTTOM_COLOR` (or
the `hourglass_glyph` function) in `tool/generate_icons.py` and rerun:

```bash
pip install pillow   # if not already installed
python3 tool/generate_icons.py
dart run flutter_launcher_icons
```

## Project layout

```
lib/
  main.dart, app.dart          bootstrap, theme, top-level navigation/lifecycle
  models/                      plain data classes (TrackedApp, AppSettings, ...)
  storage/local_store.dart     on-device persistence (Hive) — the only "backend"
  services/
    platform_bridge.dart       the one MethodChannel to native code
    limit_monitor.dart         app-wide state; screens read/write through this
  screens/                     onboarding, home, add/edit app, settings, block
  widgets/                     total-time card, app row, ad banner
android/                       real generated Gradle project + our Kotlin enforcement code
ios/                           Swift only so far (FamilyControls/DeviceActivity/ManagedSettings) — no Xcode project yet, see iOS section above
assets/icon/                   source images for flutter_launcher_icons
tool/generate_icons.py         regenerates assets/icon/*.png (needs Pillow)
```

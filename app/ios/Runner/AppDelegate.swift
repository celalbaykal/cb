import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not a FlutterViewController")
        }
        let channel = FlutterMethodChannel(
            name: "com.screenguard.app/native",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            if #available(iOS 16.0, *) {
                ScreenTimeManager.shared.handle(call, result: result)
            } else {
                result(FlutterError(
                    code: "unsupported_ios_version",
                    message: "Screen Time monitoring needs iOS 16 or later.",
                    details: nil
                ))
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

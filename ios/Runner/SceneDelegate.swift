import Flutter
import UIKit
import UserNotifications

/// The app uses the scene-based lifecycle, so `window` is nil inside
/// `AppDelegate.didFinishLaunching`. Platform channels that need the
/// FlutterViewController's binary messenger must be registered here, once the
/// scene has connected and the root FlutterViewController exists — otherwise
/// Dart hits a MissingPluginException (e.g. the `clearBadge` call).
@objc(SceneDelegate)
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let badgeChannel = FlutterMethodChannel(
      name: "app.wensa.mobile/badge",
      binaryMessenger: controller.binaryMessenger
    )
    badgeChannel.setMethodCallHandler { call, result in
      if call.method == "clearBadge" {
        if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
          UIApplication.shared.applicationIconBadgeNumber = 0
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

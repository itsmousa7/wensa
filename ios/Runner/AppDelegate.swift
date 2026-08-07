import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NOTE: platform channels that need the FlutterViewController's binary
    // messenger are registered in SceneDelegate, since this app uses the
    // scene-based lifecycle (window is nil here at launch).
    GeneratedPluginRegistrant.register(with: self)
    removeWebViewInputAccessoryView()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// WKWebView (used by the webview_flutter plugin, e.g. the Wayl payment
// screen) automatically shows a native prev/next/done toolbar above the
// keyboard whenever a focused <input> lives inside the page — the classic
// "this looks like a browser" giveaway. There's no public API to disable
// it; WKContentView is a private class, so this swizzles its
// inputAccessoryView getter to always return nil, app-wide, once at launch.
private extension UIView {
  @objc var wansaNoInputAccessoryView: UIView? { nil }
}

private func removeWebViewInputAccessoryView() {
  guard let contentViewClass = NSClassFromString("WKContentView") as? UIView.Type else { return }
  let accessorySelector = #selector(getter: UIResponder.inputAccessoryView)
  guard
    let originalMethod = class_getInstanceMethod(contentViewClass, accessorySelector),
    let swizzledMethod = class_getInstanceMethod(
      UIView.self, #selector(getter: UIView.wansaNoInputAccessoryView))
  else { return }
  method_exchangeImplementations(originalMethod, swizzledMethod)
}

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
// screen) automatically shows a native form-navigation toolbar (prev/next
// field chevrons + a Done checkmark) above the keyboard whenever a focused
// <input> lives inside the page — the classic "this looks like a browser"
// giveaway. There's no public API to disable it, and WebKit renders it via
// two different (private) mechanisms depending on iOS version:
//   - inputAccessoryView — the older, classic accessory view.
//   - inputAssistantItem — the newer bar-button-groups API that recent iOS
//     actually uses for this exact chevrons+checkmark bar.
// WKContentView is private, so both getters are swizzled, app-wide, once
// at launch, to neutralize whichever one the running iOS version uses.
private extension UIView {
  @objc var wansaNoInputAccessoryView: UIView? { nil }
}

private extension UIResponder {
  @objc var wansaEmptyInputAssistantItem: UITextInputAssistantItem {
    let item = UITextInputAssistantItem()
    item.leadingBarButtonGroups = []
    item.trailingBarButtonGroups = []
    return item
  }
}

private func removeWebViewInputAccessoryView() {
  guard let contentViewClass = NSClassFromString("WKContentView") as? UIView.Type else { return }

  if let originalMethod = class_getInstanceMethod(
    contentViewClass, #selector(getter: UIResponder.inputAccessoryView)),
    let swizzledMethod = class_getInstanceMethod(
      UIView.self, #selector(getter: UIView.wansaNoInputAccessoryView))
  {
    method_exchangeImplementations(originalMethod, swizzledMethod)
  }

  if let originalMethod = class_getInstanceMethod(
    contentViewClass, #selector(getter: UIResponder.inputAssistantItem)),
    let swizzledMethod = class_getInstanceMethod(
      UIResponder.self, #selector(getter: UIResponder.wansaEmptyInputAssistantItem))
  {
    method_exchangeImplementations(originalMethod, swizzledMethod)
  }
}

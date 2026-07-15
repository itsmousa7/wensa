import Flutter
import UIKit
import UserNotifications
import WebKit
import OPPWAMobile

/// The app uses the scene-based lifecycle, so `window` is nil inside
/// `AppDelegate.didFinishLaunching`. Platform channels that need the
/// FlutterViewController's binary messenger must be registered here, once the
/// scene has connected and the root FlutterViewController exists — otherwise
/// Dart hits a MissingPluginException (e.g. the `clearBadge` call).
@objc(SceneDelegate)
class SceneDelegate: FlutterSceneDelegate {

  private var hyperpayResult: FlutterResult?
  private var paymentProvider: OPPPaymentProvider?
  private var challengeController: ChallengeWebViewController?

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

    let hyperpayChannel = FlutterMethodChannel(
      name: "app.wensa.mobile/hyperpay",
      binaryMessenger: controller.binaryMessenger
    )
    hyperpayChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      guard call.method == "submitCardPayment" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard self.hyperpayResult == nil else {
        result(FlutterError(code: "transaction_failed",
                            message: "A payment is already in progress", details: nil))
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_card", message: "Missing arguments", details: nil))
        return
      }
      self.hyperpayResult = result
      self.submitCard(args: args, from: controller)
    }
  }

  private func resolveSuccess(_ value: String) {
    DispatchQueue.main.async {
      self.hyperpayResult?(value)
      self.hyperpayResult = nil
    }
  }

  private func resolveError(_ code: String, _ message: String) {
    DispatchQueue.main.async {
      self.hyperpayResult?(FlutterError(code: code, message: message, details: nil))
      self.hyperpayResult = nil
    }
  }

  private func submitCard(args: [String: Any], from presenter: UIViewController) {
    let checkoutId = args["checkoutid"] as? String ?? ""
    let brand      = args["brand"] as? String ?? ""
    let number     = args["card_number"] as? String ?? ""
    let holder     = args["holder_name"] as? String ?? ""
    let month      = args["month"] as? String ?? ""
    let year       = args["year"] as? String ?? ""
    let cvv        = args["cvv"] as? String ?? ""
    let mode       = args["mode"] as? String ?? "TEST"

    guard OPPCardPaymentParams.isNumberValid(number, luhnCheck: true),
          OPPCardPaymentParams.isHolderValid(holder),
          OPPCardPaymentParams.isExpiryMonthValid(month),
          OPPCardPaymentParams.isExpiryYearValid(year),
          OPPCardPaymentParams.isCvvValid(cvv) else {
      resolveError("invalid_card", "Card details are invalid")
      return
    }

    do {
      let params = try OPPCardPaymentParams(
        checkoutID: checkoutId, paymentBrand: brand, holder: holder,
        number: number, expiryMonth: month, expiryYear: year, cvv: cvv
      )
      params.shopperResultURL = "wensa://payment-result"
      let provider = OPPPaymentProvider(mode: mode == "LIVE" ? .live : .test)
      provider.threeDSEventListener = self
      paymentProvider = provider
      let transaction = OPPTransaction(paymentParams: params)
      provider.submitTransaction(transaction) { [weak self] transaction, error in
        guard let self else { return }
        if let error {
          self.resolveError("transaction_failed", error.localizedDescription)
          return
        }
        switch transaction.type {
        case .synchronous:
          self.resolveSuccess("SYNC")
        case .asynchronous:
          guard let redirectURL = transaction.redirectURL else {
            self.resolveError("transaction_failed", "Missing 3DS redirect URL")
            return
          }
          DispatchQueue.main.async {
            self.presentChallenge(url: redirectURL, over: presenter)
          }
        default:
          self.resolveError("transaction_failed", "Invalid transaction state")
        }
      }
    } catch {
      resolveError("transaction_failed", error.localizedDescription)
    }
  }

  private func presentChallenge(url: URL, over presenter: UIViewController) {
    let vc = ChallengeWebViewController(
      url: url,
      resultScheme: "wensa",
      onCompleted: { [weak self] in
        self?.challengeController = nil
        self?.resolveSuccess("success")
      },
      onCancelled: { [weak self] in
        self?.challengeController = nil
        self?.resolveError("cancelled", "3DS challenge cancelled by user")
      }
    )
    challengeController = vc
    let nav = UINavigationController(rootViewController: vc)
    nav.modalPresentationStyle = .fullScreen
    presenter.present(nav, animated: true)
  }

  // Fallback: the shopper redirect arrived via the OS (external browser hop)
  // instead of inside our challenge WebView.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url,
       url.scheme == "wensa", url.host == "payment-result", hyperpayResult != nil {
      challengeController?.dismissHosting()
      challengeController = nil
      resolveSuccess("success")
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}

// The public API of `OPPThreeDSEventListener` in SDK 7.11 differs from the
// signature this integration was originally drafted against: both callback
// methods carry a "WithCompletion" suffix, there is an additional required
// config callback, and the challenge callback hands back a
// `UINavigationController` (not a bare `UIViewController`) for the SDK to
// push its native 3DS2 challenge screen onto. Confirmed against
// ios/HyperpaySDK/OPPWAMobile.xcframework/ios-arm64/OPPWAMobile.framework/Headers/OPPPaymentProvider.h
// and the vendor's own Demo app (CustomUIViewController.swift).
extension SceneDelegate: OPPThreeDSEventListener {
  func onThreeDSConfigRequired(completion: @escaping (OPPThreeDSConfig) -> Void) {
    completion(OPPThreeDSConfig())
  }

  func onThreeDSChallengeRequired(completion: @escaping (UINavigationController) -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard let root = self.window?.rootViewController else {
        // No presenter means the completion can never be satisfied; fail
        // deterministically so the Dart side does not hang forever.
        self.resolveError("transaction_failed", "No root view controller for 3DS challenge")
        return
      }
      let presenter = root.presentedViewController ?? root
      let nav = UINavigationController()
      presenter.present(nav, animated: true) {
        completion(nav)
      }
    }
  }
}

/// Full-screen WKWebView for the 3DS challenge page. Intercepts navigation to
/// the `wensa://payment-result` shopper redirect to signal completion.
final class ChallengeWebViewController: UIViewController, WKNavigationDelegate {
  private let url: URL
  private let resultScheme: String
  private let onCompleted: () -> Void
  private let onCancelled: () -> Void
  private var webView: WKWebView!
  private var finished = false

  init(url: URL, resultScheme: String,
       onCompleted: @escaping () -> Void, onCancelled: @escaping () -> Void) {
    self.url = url
    self.resultScheme = resultScheme
    self.onCompleted = onCompleted
    self.onCancelled = onCancelled
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = url.host
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(cancelTapped))
    webView = WKWebView(frame: .zero)
    webView.navigationDelegate = self
    view = webView
    webView.load(URLRequest(url: url))
  }

  @objc private func cancelTapped() {
    guard !finished else { return }
    finished = true
    dismiss(animated: true) { self.onCancelled() }
  }

  func dismissHosting() {
    finished = true
    presentingViewController?.dismiss(animated: true)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if navigationAction.request.url?.scheme == resultScheme {
      decisionHandler(.cancel)
      guard !finished else { return }
      finished = true
      dismiss(animated: true) { self.onCompleted() }
      return
    }
    decisionHandler(.allow)
  }
}

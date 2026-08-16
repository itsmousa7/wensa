package app.wensa.mobile

import android.app.Activity
import android.app.Application
import android.app.Dialog
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.oppwa.mobile.connect.exception.ErrorCode
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.exception.PaymentException
import com.oppwa.mobile.connect.payment.BrandsValidation
import com.oppwa.mobile.connect.payment.CheckoutInfo
import com.oppwa.mobile.connect.payment.ImagesRequest
import com.oppwa.mobile.connect.payment.card.CardPaymentParams
import com.oppwa.mobile.connect.provider.AsyncPaymentActivity
import com.oppwa.mobile.connect.provider.Connect
import com.oppwa.mobile.connect.provider.ITransactionListener
import com.oppwa.mobile.connect.provider.OppPaymentProvider
import com.oppwa.mobile.connect.provider.Transaction
import com.oppwa.mobile.connect.provider.TransactionType
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity(), ITransactionListener {

    companion object {
        private const val CHANNEL = "app.wensa.mobile/hyperpay"
        private const val SHOPPER_RESULT_URL = "wensa://payment-result"
        private const val RESULT_SCHEME = "wensa"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var challengeDialog: Dialog? = null

    // The mSDK's transaction runs asynchronously and calls back into the
    // provider, so the provider must outlive submitCard(). iOS retains it the
    // same way (SceneDelegate.paymentProvider); cleared on every terminal
    // resolve so providers don't accumulate across payments.
    private var paymentProvider: OppPaymentProvider? = null

    // The mSDK opens its 3DS web challenge (AsyncPaymentActivity) itself; these
    // hooks keep that screen inside the app's task and give it a close button.

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        application.registerActivityLifecycleCallbacks(challengeUiHook)
    }

    override fun onDestroy() {
        application.unregisterActivityLifecycleCallbacks(challengeUiHook)
        // The challenge dialog is owned by this (now dying) activity's window
        // token — leaving it up leaks the window. And a still-pending result
        // would leave the Dart future hanging forever, so drain it here.
        challengeDialog?.dismiss()
        challengeDialog = null
        pendingResult?.error(
            "transaction_failed", "Payment screen was destroyed before completion", null,
        )
        pendingResult = null
        paymentProvider = null
        super.onDestroy()
    }

    // The mSDK launches AsyncPaymentActivity with FLAG_ACTIVITY_NEW_TASK, which
    // combined with our taskAffinity="" puts the challenge in a separate task
    // (it shows up as a separate window outside the app). It starts the activity
    // through us (ThreeDSWorkflowListener returns this activity), so stripping
    // the flag here keeps the challenge inside the app's own task.
    override fun startActivity(intent: Intent?, options: Bundle?) {
        if (intent?.component?.className == AsyncPaymentActivity::class.java.name) {
            intent.flags = intent.flags and Intent.FLAG_ACTIVITY_NEW_TASK.inv()
        }
        super.startActivity(intent, options)
    }

    // The overridden async_payment_activity.xml layout adds a Wensa header with
    // a close button; the SDK doesn't know about it, so wire it to the back
    // dispatcher (the SDK's back callback cancels the challenge cleanly).
    private val challengeUiHook = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityStarted(activity: Activity) {
            if (activity !is AsyncPaymentActivity) return
            activity.findViewById<ImageButton>(R.id.wensa_challenge_close)
                ?.setOnClickListener { activity.onBackPressedDispatcher.onBackPressed() }
        }

        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
        override fun onActivityResumed(activity: Activity) {}
        override fun onActivityPaused(activity: Activity) {}
        override fun onActivityStopped(activity: Activity) {}
        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
        override fun onActivityDestroyed(activity: Activity) {}
    }

    private fun resolveSuccess(value: String) = handler.post {
        pendingResult?.success(value)
        pendingResult = null
        paymentProvider = null
    }

    private fun resolveError(code: String, message: String) = handler.post {
        pendingResult?.error(code, message, null)
        pendingResult = null
        paymentProvider = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "submitCardPayment") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("transaction_failed", "A payment is already in progress", null)
                    return@setMethodCallHandler
                }
                pendingResult = result
                fun arg(key: String) = call.argument<String>(key) ?: ""
                submitCard(
                    checkoutId = arg("checkoutid"),
                    brand = arg("brand"),
                    number = arg("card_number"),
                    holder = arg("holder_name"),
                    month = arg("month"),
                    year = arg("year"),
                    cvv = arg("cvv"),
                    mode = call.argument<String>("mode") ?: "TEST",
                )
            }
    }

    private fun submitCard(
        checkoutId: String, brand: String, number: String, holder: String,
        month: String, year: String, cvv: String, mode: String,
    ) {
        if (!CardPaymentParams.isNumberValid(number, true) ||
            !CardPaymentParams.isHolderValid(holder) ||
            !CardPaymentParams.isExpiryMonthValid(month) ||
            !CardPaymentParams.isExpiryYearValid(year) ||
            !CardPaymentParams.isCvvValid(cvv)
        ) {
            resolveError("invalid_card", "Card details are invalid")
            return
        }
        try {
            val provider = OppPaymentProvider(
                this,
                if (mode == "LIVE") Connect.ProviderMode.LIVE else Connect.ProviderMode.TEST,
            )
            paymentProvider = provider
            val params = CardPaymentParams(checkoutId, brand, number, holder, month, year, cvv)
            params.shopperResultUrl = SHOPPER_RESULT_URL
            provider.setThreeDSWorkflowListener { this }
            provider.submitTransaction(Transaction(params), this)
        } catch (e: PaymentException) {
            resolveError("transaction_failed", e.error.errorMessage ?: "Transaction failed")
        } catch (e: Throwable) {
            // Provider construction and submitTransaction can also throw plain
            // runtime exceptions (bad argument/state, NPE inside the mSDK). If
            // one escaped, pendingResult would stay set forever: the Dart future
            // never completes and every later payment is rejected with
            // "A payment is already in progress" until the app is killed.
            resolveError("transaction_failed", e.message ?: "Transaction failed")
        }
    }

    // ── ITransactionListener ─────────────────────────────────────────────────

    override fun transactionCompleted(transaction: Transaction) {
        if (transaction.transactionType == TransactionType.SYNC) {
            resolveSuccess("SYNC")
            return
        }
        // When threeDS2Info is present the mSDK already ran the 3DS2 challenge
        // itself (in-app web AsyncPaymentActivity or native ipworks3ds) before
        // this callback fired. transaction.redirectUrl still holds the original
        // — now consumed — challenge URL; opening it again just shows HyperPay's
        // "no payment session found" error page.
        if (transaction.threeDS2Info != null) {
            resolveSuccess("success")
            return
        }
        val url = transaction.redirectUrl
        if (url == null) {
            resolveError("transaction_failed", "Missing 3DS redirect URL")
        } else {
            handler.post { showChallengeDialog(url) }
        }
    }

    override fun transactionFailed(transaction: Transaction, error: PaymentError) {
        val cancelled = error.errorCode in setOf(
            ErrorCode.ERROR_CODE_THREEDS2_CANCELED, ErrorCode.ERROR_CODE_GENERAL_CANCEL,
        )
        if (cancelled) {
            resolveError("cancelled", error.errorMessage ?: "Payment cancelled by user")
        } else {
            resolveError("transaction_failed", error.errorMessage ?: "Transaction failed")
        }
    }

    override fun brandsValidationRequestSucceeded(validation: BrandsValidation) {}
    override fun brandsValidationRequestFailed(error: PaymentError) {}
    override fun imagesRequestSucceeded(request: ImagesRequest) {}
    override fun imagesRequestFailed() {}
    override fun paymentConfigRequestSucceeded(info: CheckoutInfo) {}
    override fun paymentConfigRequestFailed(error: PaymentError) {}

    // ── 3DS challenge WebView (full-screen dialog, Wensa dark header) ────────

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics,
    ).toInt()

    private fun showChallengeDialog(url: String) {
        // Posted work can land after the activity is gone; showing a dialog on a
        // destroyed activity's window token throws BadTokenException.
        if (isFinishing || isDestroyed) {
            resolveError("transaction_failed", "Payment screen is no longer available")
            return
        }
        // The transaction may already have been resolved while this was queued
        // (e.g. onNewIntent won the race on the wensa:// redirect). Showing a
        // non-cancelable dialog for a finished payment traps the user.
        if (pendingResult == null) return

        val dialog = Dialog(this, android.R.style.Theme_DeviceDefault_NoActionBar)
        challengeDialog = dialog
        dialog.setCancelable(false)

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        val headerColor = ContextCompat.getColor(this, R.color.wensa_challenge_header)
        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(headerColor)
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(56),
            )
        }
        val closeBtn = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.WHITE)
            background = null
            setPadding(dp(12), 0, dp(12), 0)
        }
        toolbar.addView(closeBtn, LinearLayout.LayoutParams(dp(48), dp(56)))
        val urlLabel = TextView(this).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = TextUtils.TruncateAt.MIDDLE
            text = runCatching { Uri.parse(url).host }.getOrNull() ?: url
        }
        toolbar.addView(urlLabel, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        toolbar.addView(View(this), LinearLayout.LayoutParams(dp(48), dp(56)))
        root.addView(toolbar)

        val progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            isIndeterminate = true
            visibility = View.GONE
        }
        root.addView(progress, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        ))

        val webView = WebView(this)
        root.addView(webView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        dialog.setContentView(root)
        dialog.window?.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
        )

        closeBtn.setOnClickListener {
            dialog.dismiss()
            resolveError("cancelled", "3DS challenge cancelled by user")
        }

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
        }
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                if (request.url.scheme == RESULT_SCHEME) {
                    dialog.dismiss()
                    resolveSuccess("success")
                    return true
                }
                return false
            }

            override fun onPageStarted(view: WebView, pageUrl: String, favicon: Bitmap?) {
                progress.visibility = View.VISIBLE
                runCatching { Uri.parse(pageUrl).host }.getOrNull()?.let { urlLabel.text = it }
            }

            override fun onPageFinished(view: WebView, pageUrl: String) {
                progress.visibility = View.GONE
            }
        }
        dialog.setOnDismissListener {
            challengeDialog = null
            webView.stopLoading()
            // Defer teardown: dismiss() can be triggered from inside the WebView's own
            // WebViewClient callback (shouldOverrideUrlLoading), and destroying the WebView
            // on its own callback stack is a known intermittent native-crash pattern.
            // Also detach from the view hierarchy before destroy(), per Android guidance.
            handler.post {
                (webView.parent as? ViewGroup)?.removeView(webView)
                webView.destroy()
            }
        }
        webView.loadUrl(url)
        dialog.show()
    }

    // Fallback: the 3DS flow bounced through an external browser/app and came
    // back via the wensa:// scheme instead of inside our WebView.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.scheme == RESULT_SCHEME && intent.data?.host == "payment-result" &&
            pendingResult != null
        ) {
            challengeDialog?.dismiss()
            resolveSuccess("success")
        }
    }
}

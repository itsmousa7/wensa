package app.wensa.mobile

import android.app.Dialog
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.exception.PaymentException
import com.oppwa.mobile.connect.payment.BrandsValidation
import com.oppwa.mobile.connect.payment.CheckoutInfo
import com.oppwa.mobile.connect.payment.ImagesRequest
import com.oppwa.mobile.connect.payment.card.CardPaymentParams
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

    private fun resolveSuccess(value: String) = handler.post {
        pendingResult?.success(value)
        pendingResult = null
    }

    private fun resolveError(code: String, message: String) = handler.post {
        pendingResult?.error(code, message, null)
        pendingResult = null
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
                submitCard(
                    checkoutId = call.argument<String>("checkoutid") ?: "",
                    brand = call.argument<String>("brand") ?: "",
                    number = call.argument<String>("card_number") ?: "",
                    holder = call.argument<String>("holder_name") ?: "",
                    month = call.argument<String>("month") ?: "",
                    year = call.argument<String>("year") ?: "",
                    cvv = call.argument<String>("cvv") ?: "",
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
            val params = CardPaymentParams(checkoutId, brand, number, holder, month, year, cvv)
            params.shopperResultUrl = SHOPPER_RESULT_URL
            provider.setThreeDSWorkflowListener { this }
            provider.submitTransaction(Transaction(params), this)
        } catch (e: PaymentException) {
            resolveError("transaction_failed", e.error.errorMessage ?: "Transaction failed")
        }
    }

    // ── ITransactionListener ─────────────────────────────────────────────────

    override fun transactionCompleted(transaction: Transaction) {
        if (transaction.transactionType == TransactionType.SYNC) {
            resolveSuccess("SYNC")
        } else {
            val url = transaction.redirectUrl
            if (url == null) {
                resolveError("transaction_failed", "Missing 3DS redirect URL")
            } else {
                handler.post { showChallengeDialog(url) }
            }
        }
    }

    override fun transactionFailed(transaction: Transaction, error: PaymentError) {
        resolveError("transaction_failed", error.errorMessage ?: "Transaction failed")
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
        val dialog = Dialog(this, android.R.style.Theme_DeviceDefault_NoActionBar)
        challengeDialog = dialog
        dialog.setCancelable(false)

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        val headerColor = Color.parseColor("#1A1A2E")
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
            ellipsize = android.text.TextUtils.TruncateAt.MIDDLE
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
            webView.destroy()
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

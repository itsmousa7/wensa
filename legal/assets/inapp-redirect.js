/**
 * In-app-browser download escape helper.
 *
 * Instagram/Facebook/Threads (and several other apps) open links in a
 * sandboxed in-app browser that blocks navigation to the App Store.
 *
 * Verified on-device: instagram://extbrowser is Instagram's own scheme and is
 * NOT gesture-gated, so the escape can fire on page load with no tap at all
 * (see autoAttempt). Navigating straight to an apps.apple.com URL from inside
 * the webview is what gets blocked, and a server-side redirect to it renders
 * a blank page - so the handoff scheme is the only reliable route out.
 *
 * Usage:
 *   <a href="https://apps.apple.com/..." data-store-cta>Download</a>
 *   <script src="/assets/inapp-redirect.js"></script>
 *   <script>var env = WensaInAppRedirect.init();</script>
 *
 * In a normal browser, init() leaves every [data-store-cta] anchor alone -
 * it navigates straight to its href like any other link. Inside a detected
 * in-app browser, taps on those anchors are intercepted and routed through
 * the platform-specific escape below, with an on-theme fallback modal if
 * the escape doesn't visibly succeed within ~1.5s.
 */
(function (global) {
  'use strict';

  function detect(ua) {
    ua = ua || navigator.userAgent || navigator.vendor || '';
    var isIOS = /iPhone|iPad|iPod/i.test(ua);
    var isAndroid = /Android/i.test(ua);
    // "Barcelona" is Threads' internal UA codename; it shares Instagram's webview.
    var isInstagram = /Instagram/i.test(ua) || /Barcelona/i.test(ua);
    var isFacebook = /FBAN|FBAV|FB_IAB|Messenger/i.test(ua);
    // TikTok's iOS UA says "musical_ly", NOT "TikTok" - matching only the
    // brand name let it through as a normal browser and blanked the page.
    var isOtherInApp = /TikTok|musical_ly|BytedanceWebview|LinkedInApp|Twitter|Snapchat|MicroMessenger|Line\/|WKWebView/i.test(ua);
    var isInApp = isInstagram || isFacebook || isOtherInApp;

    // Positive detection of a real browser, rather than assuming one whenever
    // the in-app list happens not to match. Blocklists here are whack-a-mole:
    // every app we fail to name used to mean an auto-redirect into a webview
    // that can't render the App Store, i.e. a white screen. Now anything we
    // can't confirm is a real browser just gets the page with buttons.
    //   iOS: Safari and Chrome/Firefox-for-iOS carry a "Safari/" token that
    //        in-app WKWebViews omit.
    //   Android: the system WebView marks itself with "; wv)".
    var isRealBrowser = !isInApp && (
      isIOS ? /Safari\//i.test(ua)
        : isAndroid ? !/;\s*wv\)/i.test(ua)
        : true
    );

    // Whether we have an escape mechanism that is actually known to work here.
    // iOS: only Instagram (instagram://extbrowser, verified on-device) and
    // Facebook (x-safari-, their own webview feature). `x-safari-` is NOT a
    // system scheme - firing it anywhere else (TikTok, Snapchat, ...) navigates
    // the page to a scheme nothing handles and leaves a white screen.
    // Android: intent:// is a platform standard that any Android webview
    // understands, so it's safe across all of them.
    var canEscape = isAndroid ? isInApp : (isIOS && (isInstagram || isFacebook));

    return {
      ua: ua,
      isIOS: isIOS,
      isAndroid: isAndroid,
      isInstagram: isInstagram,
      isFacebook: isFacebook,
      isOtherInApp: isOtherInApp,
      isInApp: isInApp,
      isRealBrowser: isRealBrowser,
      canEscape: canEscape
    };
  }

  // Safe to call either from a click handler or directly on page load.
  function escapeToSystemBrowser(env, url) {
    if (env.isIOS && env.isInstagram) {
      // Instagram/Threads intercept this custom scheme and hand off to Safari.
      // Plain `x-safari-` via location.href is silently swallowed by IG's webview.
      location.href = 'instagram://extbrowser/?url=' + encodeURIComponent(url);
    } else if (env.isIOS && env.isFacebook) {
      // window.open (not location.href) so a failure can't blank this page.
      window.open('x-safari-' + url, '_blank');
    } else if (env.isAndroid) {
      var noScheme = url.replace(/^https?:\/\//, '');
      location.href = 'intent://' + noScheme + '#Intent;scheme=https;end';
    } else {
      location.href = url;
    }
  }

  function buildModal(theme) {
    theme = Object.assign({
      accent: '#2f9bab',
      dark: '#102b30',
      bg: '#ffffff',
      muted: '#5c7a80',
      hintBg: '#eaf7f8',
      border: '#dcebed'
    }, theme || {});

    var style = document.createElement('style');
    style.textContent =
      '.wir-overlay{position:fixed;inset:0;background:rgba(16,43,48,.45);display:flex;align-items:flex-end;justify-content:center;z-index:9999;opacity:0;pointer-events:none;transition:opacity .2s ease;}' +
      '.wir-overlay.wir-open{opacity:1;pointer-events:auto;}' +
      '.wir-sheet{position:relative;background:' + theme.bg + ';color:' + theme.dark + ';width:100%;max-width:360px;border-radius:20px 20px 0 0;padding:1.5rem 1.25rem 2rem;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;transform:translateY(16px);transition:transform .2s ease;box-shadow:0 -8px 30px rgba(16,43,48,.2);text-align:start;}' +
      '.wir-overlay.wir-open .wir-sheet{transform:translateY(0);}' +
      '@media (min-width:480px){.wir-overlay{align-items:center;}.wir-sheet{border-radius:20px;}}' +
      '.wir-title{font-size:1.05rem;font-weight:700;margin-bottom:.4rem;}' +
      '.wir-desc{font-size:.9rem;color:' + theme.muted + ';line-height:1.45;margin-bottom:1rem;}' +
      '.wir-retry{display:block;width:100%;text-align:center;padding:.8rem;border-radius:12px;background:' + theme.dark + ';color:#fff;font-weight:600;font-size:.95rem;border:none;cursor:pointer;margin-bottom:.6rem;}' +
      '.wir-steps{background:' + theme.hintBg + ';border-radius:10px;padding:.7rem .85rem;font-size:.82rem;color:' + theme.dark + ';line-height:1.4;margin-bottom:.6rem;}' +
      '.wir-copy{display:flex;align-items:center;justify-content:space-between;gap:.5rem;border:1.5px solid ' + theme.border + ';border-radius:12px;padding:.6rem .85rem;font-size:.82rem;overflow:hidden;}' +
      '.wir-copy-url{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:' + theme.muted + ';}' +
      '.wir-copy button{background:none;border:none;color:' + theme.accent + ';font-weight:600;cursor:pointer;font-size:.82rem;flex-shrink:0;}' +
      '.wir-close{position:absolute;top:.75rem;inset-inline-end:.9rem;background:none;border:none;font-size:1.1rem;color:' + theme.muted + ';cursor:pointer;line-height:1;}';
    document.head.appendChild(style);

    var overlay = document.createElement('div');
    overlay.className = 'wir-overlay';
    overlay.setAttribute('dir', 'rtl');
    overlay.innerHTML =
      '<div class="wir-sheet">' +
        '<button class="wir-close" type="button" aria-label="سكّر">✕</button>' +
        '<div class="wir-title">افتحها بالمتصفح مالتك</div>' +
        '<div class="wir-desc">المتصفح مال التطبيق ما يخلي التحميل يشتغل. كمّل بالمتصفح العادي.</div>' +
        '<button class="wir-retry" type="button">افتحها بمتصفحي</button>' +
        '<div class="wir-steps">دوس على <strong>•••</strong> (أو <strong>⋮</strong>) بالفوق واختار <strong>&quot;فتح في المتصفح&quot;</strong>.</div>' +
        '<div class="wir-copy"><span class="wir-copy-url"></span><button type="button" class="wir-copy-btn">انسخ اللنك</button></div>' +
      '</div>';
    document.body.appendChild(overlay);

    var urlEl = overlay.querySelector('.wir-copy-url');
    var copyBtn = overlay.querySelector('.wir-copy-btn');
    var retryBtn = overlay.querySelector('.wir-retry');
    var closeBtn = overlay.querySelector('.wir-close');

    var currentUrl = '';
    var currentEnv = null;

    function hide() { overlay.classList.remove('wir-open'); }
    closeBtn.addEventListener('click', hide);
    overlay.addEventListener('click', function (e) { if (e.target === overlay) hide(); });

    // Runs inside the button's own click handler, so it's still a real user
    // gesture - the retry gets the same synchronous-escape treatment.
    retryBtn.addEventListener('click', function () {
      if (currentEnv && currentUrl) escapeToSystemBrowser(currentEnv, currentUrl);
    });

    copyBtn.addEventListener('click', function () {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(currentUrl).then(function () {
          copyBtn.textContent = 'انتسخ!';
          setTimeout(function () { copyBtn.textContent = 'انسخ اللنك'; }, 1500);
        });
      }
    });

    return {
      show: function (url, env) {
        currentUrl = url;
        currentEnv = env;
        var display = url.replace(/^https?:\/\//, '');
        urlEl.textContent = display.length > 40 ? display.slice(0, 40) + '…' : display;
        overlay.classList.add('wir-open');
      },
      hide: hide
    };
  }

  // Fires the escape, watches for a real navigation-away signal, and falls
  // back to the modal if nothing happened within ~1.5s. Shared by both the
  // explicit CTA buttons and the whole-page tap-to-continue listener below.
  // showModalOnFail is false for the no-gesture attempt on page load, where a
  // modal popping up unprompted would be worse than silently showing the page.
  function attemptEscape(env, url, modal, showModalOnFail) {
    var settled = false;

    function settle() {
      if (settled) return;
      settled = true;
      cleanup();
    }
    function onVisibility() { if (document.hidden) settle(); }
    function cleanup() {
      document.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('pagehide', settle);
      window.removeEventListener('blur', settle);
    }

    document.addEventListener('visibilitychange', onVisibility);
    window.addEventListener('pagehide', settle);
    window.addEventListener('blur', settle);

    escapeToSystemBrowser(env, url);

    setTimeout(function () {
      if (!settled) {
        cleanup();
        if (showModalOnFail !== false) modal.show(url, env);
      }
    }, 1500);
  }

  function wireLink(link, env, modal, targetFor) {
    link.addEventListener('click', function (evt) {
      // Only intercept where we have a working escape. Normal browsers and
      // in-app browsers without one both fall through to real anchor
      // navigation, which is the best available behaviour for them.
      if (!env.canEscape) return;
      evt.preventDefault();
      attemptEscape(env, targetFor(link.getAttribute('href')), modal);
    });
  }

  // Makes the very first tap anywhere on the page (outside the explicit CTAs
  // and the fallback modal) trigger the escape for the visiting device's
  // store. This is the closest thing to "tap the shared link and you're
  // done" that iOS/Android in-app browsers allow - a *fully* automatic
  // page-load redirect gets silently blocked (see file header), so a single
  // unmissable first tap is the practical floor.
  function wireWholePage(env, modal, url) {
    if (!env.canEscape || !url) return;

    var fired = false;
    function handler(evt) {
      if (fired) return;
      var el = evt.target;
      // Let dedicated handlers own taps on the CTAs themselves and the modal.
      if (el.closest && (el.closest('[data-store-cta]') || el.closest('.wir-overlay'))) return;
      fired = true;
      document.removeEventListener('click', handler, true);
      attemptEscape(env, url, modal);
    }
    document.addEventListener('click', handler, true);
  }

  function init(options) {
    options = options || {};
    var env = detect();
    var modal = buildModal(options.theme);

    // When browserTarget is set we hand the system browser our own URL instead
    // of a store URL, so the server-side UA redirect picks the store. That
    // keeps device detection in one place (the edge) and handles iPad and
    // unusual UAs that this script would otherwise have to special-case.
    function targetFor(storeUrl) {
      return options.browserTarget || storeUrl;
    }

    var links = document.querySelectorAll(options.selector || '[data-store-cta]');
    for (var i = 0; i < links.length; i++) {
      wireLink(links[i], env, modal, targetFor);
    }

    var iosLink = document.querySelector('[data-store-cta="ios"]');
    var androidLink = document.querySelector('[data-store-cta="android"]');
    var storeUrl = env.isIOS ? (iosLink && iosLink.getAttribute('href'))
      : env.isAndroid ? (androidLink && androidLink.getAttribute('href'))
      : null;
    var escapeUrl = storeUrl ? targetFor(storeUrl) : options.browserTarget;

    if (options.wholePage) {
      wireWholePage(env, modal, escapeUrl);
    }

    // Fire the escape on load, with no tap needed. Navigating straight to the
    // App Store from a webview is gesture-gated by WebKit, but
    // instagram://extbrowser is Instagram's own scheme and is exempt (verified
    // on-device). Deliberately unguarded: this must run on *every* visit, not
    // just the first. A persisted "already attempted" flag would make repeat
    // visits silently fall through to the page. There is no loop risk, since
    // the escape hands off to the external browser, where isInApp is false and
    // this branch never runs. No modal on failure - the tap handlers above
    // remain as the fallback.
    if (options.autoAttempt && env.canEscape && escapeUrl) {
      attemptEscape(env, escapeUrl, modal, false);
    }

    return env;
  }

  global.WensaInAppRedirect = { detect: detect, init: init };
})(window);

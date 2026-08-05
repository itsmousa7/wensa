import { applyLang, currentLang, initLangToggle } from "./i18n.js";
import { initReveals, initNav, initParallax, initCounters, initLineDraw } from "./motion.js";
import { initRotator } from "./rotator.js";

// The <head> snippet already set lang/dir before paint. Re-applying here fills
// in the text nodes, which the snippet deliberately does not touch.
applyLang(currentLang());
initLangToggle();

initNav();
initReveals();
initParallax();
initCounters();
initLineDraw();
initRotator();

// Store buttons only. Unlike /download, this page must NOT use
// { wholePage: true, autoAttempt: true } — wholePage makes the first tap
// anywhere jump to the App Store, which would break every link on a marketing
// page, and autoAttempt would fire an escape before the visitor reads anything.
if (window.WensaInAppRedirect) window.WensaInAppRedirect.init();

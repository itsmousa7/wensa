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

// Store buttons only. Unlike /download, this page must NOT opt into the
// redirect helper's "whole page" tap-to-store mode or its on-load escape
// attempt — the former would break every link on a marketing page by making
// the first tap anywhere jump to the App Store, and the latter would fire
// before the visitor has read anything. Init with defaults only.
if (window.WensaInAppRedirect) window.WensaInAppRedirect.init();

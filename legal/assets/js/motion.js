// Scroll-driven motion. Pacing follows WENSA_BRAND_SKILL.md §8 — calm and
// confident, ease-out, nothing bouncy.
//
// Everything here animates transform and opacity only. One shared rAF-throttled
// scroll listener drives nav state and parallax so N elements cost one handler.

const REDUCE = "(prefers-reduced-motion: reduce)";

export function prefersReducedMotion() {
  return window.matchMedia(REDUCE).matches;
}

/**
 * How far to shift a parallax element, in pixels.
 *
 * Pure so it can be tested without a DOM. Returns 0 when the element's top sits
 * at the viewport's vertical centre, and ramps to ±strength as it approaches
 * either edge. The result is clamped so an element far off-screen never flies
 * away. Takes no scroll position: elTop comes from getBoundingClientRect(),
 * which is already viewport-relative.
 */
export function parallaxOffset(elTop, viewportH, strength) {
  const centre = viewportH / 2;
  const fromCentre = (centre - elTop) / centre; // -1 … 1 across the viewport
  const clamped = Math.max(-1, Math.min(1, fromCentre));
  return clamped * strength;
}

export function initReveals() {
  const targets = document.querySelectorAll("[data-reveal]");
  if (prefersReducedMotion()) {
    for (const el of targets) el.classList.add("is-in");
    return;
  }
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("is-in");
        io.unobserve(entry.target); // reveal is one-way; stop paying for it
      }
    },
    { threshold: 0.15, rootMargin: "0px 0px -8% 0px" }
  );
  for (const el of targets) io.observe(el);
}

export function initNav() {
  const nav = document.querySelector("[data-nav]");
  if (!nav) return;
  const update = () => nav.classList.toggle("is-scrolled", window.scrollY > 40);
  update();
  onScroll(update);
}

export function initParallax() {
  const items = [...document.querySelectorAll("[data-parallax]")];
  if (!items.length || prefersReducedMotion()) return;
  const update = () => {
    const vh = window.innerHeight;
    for (const el of items) {
      const strength = Number(el.dataset.parallax) || 20;
      const top = el.getBoundingClientRect().top;
      const y = parallaxOffset(top, vh, strength);
      el.style.transform = `translate3d(0, ${y.toFixed(2)}px, 0)`;
    }
  };
  update();
  onScroll(update);
}

export function initCounters() {
  const items = document.querySelectorAll("[data-counter]");
  if (!items.length) return;
  if (prefersReducedMotion()) {
    for (const el of items) el.textContent = formatNumber(el, Number(el.dataset.counter));
    return;
  }
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        io.unobserve(entry.target);
        rollUp(entry.target, Number(entry.target.dataset.counter), 1400);
      }
    },
    { threshold: 0.5 }
  );
  for (const el of items) io.observe(el);
}

export function initLineDraw() {
  const paths = document.querySelectorAll("[data-line-draw]");
  if (!paths.length) return;
  for (const path of paths) {
    const len = path.getTotalLength();
    path.style.strokeDasharray = String(len);
    path.style.strokeDashoffset = prefersReducedMotion() ? "0" : String(len);
  }
  if (prefersReducedMotion()) return;
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        io.unobserve(entry.target);
        entry.target.style.transition = "stroke-dashoffset 1.2s var(--ease)";
        entry.target.style.strokeDashoffset = "0";
      }
    },
    { threshold: 0.3 }
  );
  for (const path of paths) io.observe(path);
}

// ── internals ────────────────────────────────────────────────────────────

let handlers = [];
let ticking = false;

function onScroll(fn) {
  handlers.push(fn);
  if (handlers.length > 1) return; // one listener serves every subscriber
  window.addEventListener(
    "scroll",
    () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        for (const h of handlers) h();
        ticking = false;
      });
    },
    { passive: true }
  );
  window.addEventListener("resize", () => { for (const h of handlers) h(); }, { passive: true });
}

function formatNumber(el, value) {
  const locale = document.documentElement.lang === "ar" ? "ar-EG" : "en-US";
  const suffix = el.dataset.counterSuffix ?? "";
  return new Intl.NumberFormat(locale).format(Math.round(value)) + suffix;
}

function rollUp(el, target, duration) {
  const start = performance.now();
  const tick = (now) => {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3); // ease-out-cubic
    el.textContent = formatNumber(el, target * eased);
    if (t < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}

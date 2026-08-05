// The hero's cycling word.
//
// The outgoing word slides up out of a clipping mask while the incoming word
// rises into the same slot. The slot's width animates to the incoming word's
// measured width so the rest of the headline reflows smoothly instead of
// snapping. Widths are measured once per language into an off-screen mirror,
// because measuring during the transition would read a mid-animation value.

import { ROTATIONS, currentLang } from "./i18n.js";
import { prefersReducedMotion } from "./motion.js";

const INTERVAL = 2200;
const SWAP = 520; // must match --rotator-swap in site.css

export function nextIndex(i, total) {
  return (i + 1) % total;
}

export function initRotator(root = document) {
  const slot = root.querySelector("[data-rotator]");
  if (!slot) return;

  let words = ROTATIONS[currentLang()];
  let index = 0;
  let timer = null;

  const mirror = document.createElement("span");
  mirror.className = "rotator__mirror";
  mirror.setAttribute("aria-hidden", "true");
  slot.parentElement.appendChild(mirror);

  const measure = (word) => {
    mirror.textContent = word;
    return mirror.getBoundingClientRect().width;
  };

  const render = (word, animate) => {
    slot.style.setProperty("--rotator-w", `${measure(word).toFixed(1)}px`);
    if (!animate) {
      slot.textContent = word;
      return;
    }
    slot.classList.add("is-out");
    setTimeout(() => {
      slot.textContent = word;
      slot.classList.remove("is-out");
      slot.classList.add("is-in");
      setTimeout(() => slot.classList.remove("is-in"), SWAP);
    }, SWAP / 2);
  };

  const start = () => {
    stop();
    if (prefersReducedMotion() || words.length < 2) return;
    timer = setInterval(() => {
      index = nextIndex(index, words.length);
      render(words[index], true);
    }, INTERVAL);
  };

  const stop = () => {
    if (timer) clearInterval(timer);
    timer = null;
  };

  // Restart from the top in the new language, so the two languages never drift
  // into showing unrelated words at the same position in the cycle.
  document.addEventListener("wensa:langchange", () => {
    words = ROTATIONS[currentLang()];
    index = 0;
    render(words[0], false);
    start();
  });

  // Don't burn frames or battery while the tab is hidden.
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) stop();
    else start();
  });

  render(words[0], false);
  start();
}

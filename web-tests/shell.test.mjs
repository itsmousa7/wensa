import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, i18nKeys, PAGES } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

const DASHBOARD = "https://dashboard.wensa.app";

for (const page of PAGES) {
  test(`${page} has a nav with a language toggle`, () => {
    const html = readLegal(page);
    assert.match(html, /<header[^>]*data-nav/, "nav must carry data-nav for the scroll state");
    assert.match(html, /data-lang-toggle/, "a language toggle button is required");
  });

  test(`${page} has a skip link as the first focusable element`, () => {
    const html = readLegal(page);
    const bodyStart = html.indexOf("<body");
    const skip = html.indexOf('href="#main"', bodyStart);
    const firstLink = html.indexOf("<a ", bodyStart);
    assert.ok(skip > -1, "a skip-to-content link is required");
    assert.ok(skip - firstLink < 80, "the skip link must be the first anchor in the body");
  });

  test(`${page} points its merchant CTA at the dashboard`, () => {
    assert.ok(readLegal(page).includes(DASHBOARD) || page === "index.html",
      "merchants.html must link to the dashboard");
  });

  test(`${page} declares a viewport and charset`, () => {
    const html = readLegal(page);
    assert.match(html, /<meta charset="UTF-8">/i);
    assert.match(html, /name="viewport"[^>]*width=device-width/);
  });

  test(`${page} loads main.js as a module and inapp-redirect as a classic script`, () => {
    const html = readLegal(page);
    assert.match(html, /<script type="module" src="\/assets\/js\/main\.js">/);
    assert.match(html, /<script src="\/assets\/inapp-redirect\.js">/,
      "inapp-redirect.js is a classic IIFE and must not be loaded as a module");
  });
}

test("index.html links to the merchants page", () => {
  assert.match(readLegal("index.html"), /href="\/merchants"/);
});

test("merchants.html links back to the landing page", () => {
  assert.match(readLegal("merchants.html"), /href="\/"/);
});

// This is the first task where markup actually references the seeded nav.*
// and footer.* keys, so it is also the first point where "no orphan keys"
// can hold. Every later task adds its own keys and markup together, so this
// stays true through the rest of the plan.
test("no dictionary key is unused", () => {
  const used = new Set(PAGES.flatMap((p) => i18nKeys(readLegal(p))));
  const orphans = Object.keys(dict.ar).filter((k) => !used.has(k) && !k.startsWith("meta."));
  assert.deepEqual(orphans, [], "these keys are defined but never referenced in the HTML");
});

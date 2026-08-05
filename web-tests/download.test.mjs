import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { LEGAL_DIR, readLegal, legalExists } from "./helpers.mjs";

const IOS = "https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862";
const ANDROID = "https://play.google.com/store/apps/details?id=app.wensa.mobile";

test("store URLs on the landing page match the ones download.html already uses", () => {
  const landing = readLegal("index.html");
  const download = readLegal("download.html");
  assert.ok(download.includes(IOS), "the canonical iOS URL changed — update this test and the site together");
  assert.ok(landing.includes(IOS), "landing page iOS URL does not match download.html");
  assert.ok(landing.includes("id=app.wensa.mobile"), "landing page Android URL missing");
  assert.ok(download.includes("id=app.wensa.mobile"));
});

test("every store link carries a data-store-cta so inapp-redirect can intercept it", () => {
  const html = readLegal("index.html");
  const storeLinks = [...html.matchAll(/<a\b[^>]*(?:apps\.apple\.com|play\.google\.com)[^>]*>/g)].map((m) => m[0]);
  assert.ok(storeLinks.length >= 2);
  for (const link of storeLinks) {
    assert.match(link, /data-store-cta="(ios|android)"/, `store link without data-store-cta: ${link}`);
  }
});

test("the landing page does NOT enable wholePage or autoAttempt", () => {
  const js = readLegal("assets/js/main.js");
  assert.ok(!/wholePage/.test(js),
    "wholePage makes the first tap anywhere jump to the store — correct for /download, wrong here");
  assert.ok(!/autoAttempt/.test(js),
    "autoAttempt fires an escape on load before the visitor has read anything");
  assert.match(js, /WensaInAppRedirect\.init\(\)/);
});

test("character cutouts exist and are transparent PNGs", () => {
  for (const name of ["character-thumbsup.png", "character-register.png"]) {
    const rel = `assets/img/${name}`;
    assert.ok(legalExists(rel), `${rel} is missing`);
    const buf = readFileSync(join(LEGAL_DIR, rel));
    assert.equal(buf.readUInt32BE(0), 0x89504e47, `${rel} is not a PNG`);
    // IHDR color type lives at byte 25; 6 = RGBA, 4 = grey+alpha.
    assert.ok([4, 6].includes(buf[25]), `${rel} has no alpha channel — background was not removed`);
  }
});

test("the merchant band links to the merchants page", () => {
  const html = readLegal("index.html");
  const band = html.slice(html.indexOf('class="band"'));
  assert.match(band, /href="\/merchants"/);
});

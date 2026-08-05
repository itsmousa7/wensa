import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, PAGES } from "./helpers.mjs";

for (const page of PAGES) {
  test(`${page} has a title and description`, () => {
    const html = readLegal(page);
    assert.match(html, /<title>[^<]{10,}<\/title>/);
    assert.match(html, /<meta name="description" content="[^"]{20,}"/);
  });

  test(`${page} has a complete Open Graph card`, () => {
    const html = readLegal(page);
    for (const prop of ["og:type", "og:title", "og:description", "og:image", "og:url", "og:locale"]) {
      assert.match(html, new RegExp(`property="${prop}"`), `${prop} is missing`);
    }
    assert.match(html, /content="https:\/\/wensa\.app\/assets\/og-wensa\.jpg"/,
      "og:image must be an absolute URL — scrapers do not resolve relative paths");
  });

  test(`${page} declares its alternate language`, () => {
    const html = readLegal(page);
    assert.match(html, /rel="alternate"[^>]*hreflang="ar"/);
    assert.match(html, /rel="alternate"[^>]*hreflang="en"/);
  });

  test(`${page} has a canonical URL`, () => {
    assert.match(readLegal(page), /rel="canonical"/);
  });
}

test("the landing page declares the Arabic Iraqi locale", () => {
  assert.match(readLegal("index.html"), /property="og:locale" content="ar_IQ"/);
});

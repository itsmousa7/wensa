import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, PAGES } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

for (const page of PAGES) {
  test(`${page} has a title and description`, () => {
    const html = readLegal(page);
    assert.match(html, /<title[^>]*>[^<]{10,}<\/title>/);
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

// applyLang() only ever swaps [data-i18n]/[data-i18n-attr] nodes — it never
// touches <title> or <meta> directly. So the head metadata only translates if
// these elements are wired into that same mechanism. Without this wiring, the
// hreflang="en" alternate link is a lie: the "English" variant it points at
// renders byte-identical Arabic <title>/description/og:* markup.
for (const [page, titleKey, descKey] of [
  ["index.html", "meta.home.title", "meta.home.desc"],
  ["merchants.html", "meta.merchants.title", "meta.merchants.desc"],
]) {
  test(`${page} <title> is wired to translate via data-i18n`, () => {
    const html = readLegal(page);
    const titleTag = html.match(/<title[^>]*>[^<]*<\/title>/)?.[0] ?? "";
    assert.match(titleTag, new RegExp(`data-i18n="${titleKey}"`),
      `<title> must carry data-i18n="${titleKey}" so the toggle translates the tab title`);
  });

  test(`${page} description and og:title/og:description meta tags are wired to translate`, () => {
    const html = readLegal(page);
    const descTag = html.match(/<meta name="description"[^>]*>/)?.[0] ?? "";
    assert.match(descTag, new RegExp(`data-i18n-attr="content:${descKey}"`),
      `meta description must carry data-i18n-attr="content:${descKey}"`);

    const ogTitleTag = html.match(/<meta property="og:title"[^>]*>/)?.[0] ?? "";
    assert.match(ogTitleTag, new RegExp(`data-i18n-attr="content:${titleKey}"`),
      `og:title must carry data-i18n-attr="content:${titleKey}"`);

    const ogDescTag = html.match(/<meta property="og:description"[^>]*>/)?.[0] ?? "";
    assert.match(ogDescTag, new RegExp(`data-i18n-attr="content:${descKey}"`),
      `og:description must carry data-i18n-attr="content:${descKey}"`);
  });

  test(`${page} leaves canonical, og:url and hreflang untouched (structural, not translatable)`, () => {
    const html = readLegal(page);
    for (const tag of [
      html.match(/<link rel="canonical"[^>]*>/)?.[0] ?? "",
      html.match(/<meta property="og:url"[^>]*>/)?.[0] ?? "",
      ...[...html.matchAll(/<link rel="alternate"[^>]*>/g)].map((m) => m[0]),
    ]) {
      assert.doesNotMatch(tag, /data-i18n/, `${tag} must not carry a data-i18n attribute — it is URL/structural metadata`);
    }
  });
}

test("og:locale is wired to translate via data-i18n-attr", () => {
  for (const page of PAGES) {
    const html = readLegal(page);
    const ogLocaleTag = html.match(/<meta property="og:locale"[^>]*>/)?.[0] ?? "";
    assert.match(ogLocaleTag, /data-i18n-attr="content:meta\.ogLocale"/,
      `${page}'s og:locale must carry data-i18n-attr="content:meta.ogLocale"`);
  }
});

test("all meta.* dictionary keys exist with non-empty values in both languages", () => {
  const keys = [
    "meta.home.title", "meta.home.desc",
    "meta.merchants.title", "meta.merchants.desc",
    "meta.ogLocale",
  ];
  for (const lang of ["ar", "en"]) {
    for (const key of keys) {
      assert.ok(key in dict[lang], `dict.${lang} is missing "${key}"`);
      assert.ok(String(dict[lang][key]).trim().length > 0, `dict.${lang}.${key} is empty`);
    }
  }
});

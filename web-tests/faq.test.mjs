import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

test("the FAQ uses native details/summary so it works without JS", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="faq"'));
  assert.equal((section.match(/<details/g) ?? []).length, 4);
  assert.equal((section.match(/<summary/g) ?? []).length, 4);
});

test("every FAQ question has an answer key in both languages", () => {
  for (const n of [1, 2, 3, 4]) {
    for (const lang of ["ar", "en"]) {
      assert.ok(dict[lang][`faq.q${n}`], `${lang}.faq.q${n} missing`);
      assert.ok(dict[lang][`faq.a${n}`], `${lang}.faq.a${n} missing`);
    }
  }
});

test("the closing CTA sends merchants to the dashboard", () => {
  const html = readLegal("merchants.html");
  const closing = html.slice(html.indexOf('class="band"'));
  assert.match(closing, /https:\/\/dashboard\.wensa\.app/);
});

// Spec section 10b: the answers are supplied by the business, not invented here.
// This test documents which ones are still placeholders. Delete the entries from
// PENDING as each real answer lands; the test then guards them against regression.
const PENDING = ["faq.a1", "faq.a2", "faq.a3", "faq.a4"];

test("placeholder answers are explicitly marked, never silently invented", () => {
  for (const key of PENDING) {
    assert.match(dict.ar[key], /\[PENDING\]/,
      `ar.${key} must stay marked until the business supplies the real answer`);
    assert.match(dict.en[key], /\[PENDING\]/,
      `en.${key} must stay marked until the business supplies the real answer`);
  }
});

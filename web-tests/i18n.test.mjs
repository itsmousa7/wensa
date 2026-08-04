import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, i18nKeys, PAGES } from "./helpers.mjs";
import { dict, ROTATIONS } from "../legal/assets/js/i18n.js";

test("ar and en dictionaries have identical key sets", () => {
  const ar = Object.keys(dict.ar).sort();
  const en = Object.keys(dict.en).sort();
  const missingEn = ar.filter((k) => !(k in dict.en));
  const missingAr = en.filter((k) => !(k in dict.ar));
  assert.deepEqual(missingEn, [], "keys present in ar but missing from en");
  assert.deepEqual(missingAr, [], "keys present in en but missing from ar");
});

test("no dictionary value is empty", () => {
  for (const lang of ["ar", "en"]) {
    for (const [key, value] of Object.entries(dict[lang])) {
      assert.ok(String(value).trim().length > 0, `${lang}.${key} is empty`);
    }
  }
});

test("every data-i18n key used in the HTML exists in both dictionaries", () => {
  for (const page of PAGES) {
    for (const key of i18nKeys(readLegal(page))) {
      assert.ok(key in dict.ar, `${page} uses "${key}" but dict.ar has no such key`);
      assert.ok(key in dict.en, `${page} uses "${key}" but dict.en has no such key`);
    }
  }
});

test("hero rotations are the same length in both languages", () => {
  assert.ok(ROTATIONS.ar.length >= 3, "need at least 3 rotating words");
  assert.equal(ROTATIONS.ar.length, ROTATIONS.en.length,
    "the rotation cycle must be the same length in both languages");
});

test("Arabic copy uses Arabic-Indic numerals, not Western digits", () => {
  const offenders = Object.entries(dict.ar)
    .filter(([, v]) => /[0-9]/.test(v))
    .map(([k]) => k);
  assert.deepEqual(offenders, [], "Arabic copy must use ٠١٢٣٤٥٦٧٨٩ per the brand copy rules");
});

test("both pages set the language before first paint", () => {
  for (const page of PAGES) {
    const html = readLegal(page);
    const headEnd = html.indexOf("</head>");
    const boot = html.slice(0, headEnd);
    assert.match(boot, /wensa_lang/,
      `${page} must read the stored language in <head> to avoid a flash of the wrong language`);
    assert.match(boot, /document\.documentElement\.lang/, `${page} must set lang in <head>`);
  }
});

import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

test("the offer states both perks and that they cover the first month", () => {
  assert.match(dict.ar["offer.title"], /شهر/, "the Arabic offer must say 'month'");
  assert.match(dict.ar["offer.title"], /٠٪|صفر/, "the Arabic offer must state 0% commission");
  assert.match(dict.en["offer.title"], /month/i);
  assert.match(dict.en["offer.title"], /0%/);
});

test("the fine print names the after-price so the offer is not misleading", () => {
  assert.match(dict.ar["offer.fine"], /٦٠٬٠٠٠|٦٠،٠٠٠/, "Arabic fine print must state 60,000 in Arabic-Indic digits");
  assert.match(dict.en["offer.fine"], /60,000/);
  assert.match(dict.en["offer.fine"], /IQD/);
});

test("the free plan is stated so nobody thinks a paid plan is mandatory", () => {
  assert.match(dict.ar["offer.free"], /مجاني/, "must reassure that a free plan exists");
  assert.match(dict.en["offer.free"], /free/i);
});

test("orange is used exactly once on the merchants page", () => {
  const html = readLegal("merchants.html");
  const hits = (html.match(/offer__badge/g) ?? []).length;
  assert.equal(hits, 1, "ORANGE is the offer badge and nothing else — one hit per frame");
});

test("both merchant CTAs point at the dashboard", () => {
  const html = readLegal("merchants.html");
  const links = (html.match(/https:\/\/dashboard\.wensa\.app/g) ?? []).length;
  assert.ok(links >= 2, `expected at least 2 dashboard links (nav + hero), found ${links}`);
});

test("the merchant hero uses the register character", () => {
  assert.match(readLegal("merchants.html"), /character-register\.png/);
});

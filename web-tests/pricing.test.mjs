import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

const PLANS_TSX =
  "/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard/src/features/merchant/PlansPage.tsx";

test("prices match the dashboard's PlansPage.tsx", { skip: !existsSync(PLANS_TSX) }, () => {
  const tsx = readFileSync(PLANS_TSX, "utf8");
  assert.ok(tsx.includes('price: "25,000"'), "Growth is no longer 25,000 in the dashboard — update the site");
  assert.ok(tsx.includes('price: "60,000"'), "Pro is no longer 60,000 in the dashboard — update the site");
  assert.match(dict.en["plan.growth.price"], /25,000/);
  assert.match(dict.en["plan.pro.price"], /60,000/);
  assert.match(dict.ar["plan.growth.price"], /٢٥٬٠٠٠|٢٥،٠٠٠/);
  assert.match(dict.ar["plan.pro.price"], /٦٠٬٠٠٠|٦٠،٠٠٠/);
});

test("all three plans are on the page", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="pricing"'));
  assert.equal((section.match(/class="plan[ "]/g) ?? []).length, 3);
});

test("Basic is presented as free", () => {
  assert.match(dict.ar["plan.basic.price"], /مجاني/);
  assert.match(dict.en["plan.basic.price"], /free/i);
});

test("Growth carries the most-popular badge, matching the dashboard", () => {
  assert.match(dict.ar["plan.growth.badge"], /الأكثر شيوعاً/);
  assert.match(dict.en["plan.growth.badge"], /Most Popular/i);
  const section = readLegal("merchants.html");
  assert.equal((section.match(/plan__badge/g) ?? []).length, 1, "exactly one plan may be badged");
});

test("Pro notes that the first month is free", () => {
  assert.match(dict.ar["plan.pro.note"], /شهر/);
  assert.match(dict.en["plan.pro.note"], /first month/i);
});

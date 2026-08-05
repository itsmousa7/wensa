import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";

test("there are six benefit cards", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="benefits"'), html.indexOf('id="join"'));
  assert.equal((section.match(/class="card card--flat"/g) ?? []).length, 6);
});

test("there are four join steps with an animated connector", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="join"'), html.indexOf('id="pricing"'));
  assert.equal((section.match(/class="step"/g) ?? []).length, 4);
  assert.match(section, /data-line-draw/);
});

test("step numbers use Arabic-Indic digits in the shipped markup", () => {
  const html = readLegal("merchants.html");
  const nums = [...html.matchAll(/class="step__num"[^>]*>([^<]+)</g)].map((m) => m[1].trim());
  assert.deepEqual(nums, ["١", "٢", "٣", "٤"]);
});

test("every join-step number is bilingual, not a hardcoded static digit", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="join"'), html.indexOf('id="pricing"'));
  const tags = [...section.matchAll(/<span class="step__num"[^>]*>/g)].map((m) => m[0]);
  assert.equal(tags.length, 4, "expected 4 step__num spans in the join section");
  const expectedKeys = ["num.1", "num.2", "num.3", "num.4"];
  tags.forEach((tag, i) => {
    assert.match(tag, new RegExp(`data-i18n="${expectedKeys[i]}"`),
      `step__num span ${i + 1} must carry data-i18n="${expectedKeys[i]}", not a bare digit`);
  });
});

import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";

test("the what-you-can-do section has three feature cards", () => {
  const html = readLegal("index.html");
  const section = html.slice(html.indexOf('id="what"'), html.indexOf('id="how"'));
  const cards = (section.match(/class="card"/g) ?? []).length;
  assert.equal(cards, 3, `expected 3 feature cards, found ${cards}`);
});

test("the how-it-works section has three steps and an animated connector", () => {
  const html = readLegal("index.html");
  const section = html.slice(html.indexOf('id="how"'), html.indexOf('id="trust"'));
  const steps = (section.match(/class="step"/g) ?? []).length;
  assert.equal(steps, 3, `expected 3 steps, found ${steps}`);
  assert.match(section, /data-line-draw/, "the connector path must opt into the line-draw animation");
});

test("every card and step reveals on scroll with a stagger", () => {
  const html = readLegal("index.html");
  assert.ok((html.match(/data-reveal-delay/g) ?? []).length >= 6,
    "cards and steps should stagger rather than all appearing at once");
});

test("section headings are h2, so the document outline is not broken", () => {
  const html = readLegal("index.html");
  assert.equal((html.match(/<h1/g) ?? []).length, 1, "exactly one h1 per page");
  assert.ok((html.match(/<h2/g) ?? []).length >= 3);
});

test("every step number is bilingual, not hardcoded static digits", () => {
  const html = readLegal("index.html");
  const section = html.slice(html.indexOf('id="how"'), html.indexOf('id="trust"'));
  const nums = [...section.matchAll(/<span class="step__num"[^>]*>/g)];
  assert.equal(nums.length, 3, `expected 3 step__num spans, found ${nums.length}`);
  for (const [tag] of nums) {
    assert.match(
      tag,
      /data-i18n="num\.[123]"/,
      `step__num span must carry data-i18n="num.N" so it re-renders on language switch, got: ${tag}`
    );
  }
});

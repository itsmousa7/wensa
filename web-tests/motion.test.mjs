import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { parallaxOffset } from "../legal/assets/js/motion.js";

test("parallax is zero when the element is centred in the viewport", () => {
  // elTop 400 in an 800px viewport puts the element's top at the exact centre.
  assert.equal(parallaxOffset(400, 800, 30), 0);
});

test("parallax moves in opposite directions above and below centre", () => {
  const above = parallaxOffset(100, 800, 30);
  const below = parallaxOffset(700, 800, 30);
  assert.ok(above > 0, "an element above centre should offset positively");
  assert.ok(below < 0, "an element below centre should offset negatively");
});

test("parallax is clamped to the strength argument", () => {
  for (const top of [-5000, -100, 0, 400, 1200, 9000]) {
    const v = parallaxOffset(top, 800, 30);
    assert.ok(Math.abs(v) <= 30, `offset ${v} exceeded strength 30 at top=${top}`);
  }
});

test("parallax scales linearly with strength", () => {
  assert.equal(parallaxOffset(100, 800, 60), parallaxOffset(100, 800, 30) * 2);
});

test("reduced motion collapses every animation", () => {
  const css = readLegal("assets/css/site.css");
  const start = css.indexOf("@media (prefers-reduced-motion: reduce)");
  assert.ok(start > -1, "site.css must contain a prefers-reduced-motion: reduce block");
  const block = css.slice(start); // covers this and any later reduce block
  assert.match(block, /animation[^;]*none/, "animations must be disabled");
  assert.match(block, /transition[^;]*none/, "transitions must be disabled");
  assert.match(block, /\[data-reveal\][\s\S]*?opacity\s*:\s*1/,
    "revealed elements must be visible at rest, not stuck at opacity 0");
});

test("only transform and opacity are transitioned", () => {
  const css = readLegal("assets/css/site.css");
  // The rotator is the single sanctioned exception: it animates width so the
  // headline reflows around the changing word instead of snapping. Everything
  // else must stay off the layout path.
  const rules = [...css.matchAll(/([^{}]+)\{([^}]*)\}/g)]
    .filter(([, , body]) => /transition\s*:/.test(body))
    .filter(([, selector]) => !selector.includes(".rotator__word"));

  const banned = /\b(width|height|top|left|right|bottom|margin|padding|inset)\b/;
  for (const [, selector, body] of rules) {
    const hit = body.match(/transition\s*:\s*([^;]+);/);
    assert.ok(hit, `${selector.trim()} has a transition without a trailing semicolon`);
    assert.ok(!banned.test(hit[1]),
      `${selector.trim()} transitions a layout property ("${hit[1].trim()}") — use transform instead`);
  }
});

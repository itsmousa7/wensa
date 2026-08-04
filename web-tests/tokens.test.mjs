import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";

const BRAND = {
  "--paper": "#FBFAF8",
  "--ink": "#18262B",
  "--subink": "#6C7A7E",
  "--teal": "#3490A2",
  "--orange": "#FF6F3C",
  "--yellow": "#FFD93D",
};

test("brand colors match WENSA_BRAND_SKILL.md exactly", () => {
  const css = readLegal("assets/css/base.css");
  for (const [token, hex] of Object.entries(BRAND)) {
    const re = new RegExp(`${token}\\s*:\\s*${hex}\\s*;`, "i");
    assert.match(css, re, `${token} must be exactly ${hex}`);
  }
});

test("every declared @font-face points at a file that exists", () => {
  const css = readLegal("assets/css/base.css");
  const re = /url\(\s*["']?(\/assets\/fonts\/[^"')]+)["']?\s*\)/g;
  const refs = [...css.matchAll(re)].map((m) => m[1]);
  assert.ok(refs.length >= 7, `expected at least 7 font refs, found ${refs.length}`);
});

test("fonts load with swap so text is never invisible", () => {
  const css = readLegal("assets/css/base.css");
  const faces = css.match(/@font-face\s*\{[^}]*\}/g) ?? [];
  assert.ok(faces.length >= 7);
  for (const face of faces) {
    assert.match(face, /font-display\s*:\s*swap/, "every @font-face needs font-display: swap");
  }
});

test("Arabic and English font stacks are bound to [lang]", () => {
  const css = readLegal("assets/css/base.css");
  assert.match(css, /\[lang=["']ar["']\]/, "an [lang=ar] rule must set the Arabic stack");
  assert.match(css, /\[lang=["']en["']\]/, "an [lang=en] rule must set the English stack");
});

test("the type scale is fluid, not fixed", () => {
  const css = readLegal("assets/css/base.css");
  const steps = css.match(/--step-[0-9-]+\s*:\s*clamp\(/g) ?? [];
  assert.ok(steps.length >= 5, `expected at least 5 clamp() type steps, found ${steps.length}`);
});

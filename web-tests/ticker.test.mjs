import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

const CATEGORIES = [
  "cat.sports", "cat.restaurants", "cat.music", "cat.malls", "cat.cafes",
  "cat.cinema", "cat.festivals", "cat.farms", "cat.discounts",
];

test("all nine app categories are in the dictionary", () => {
  for (const key of CATEGORIES) {
    assert.ok(key in dict.ar, `${key} missing from dict.ar`);
    assert.ok(key in dict.en, `${key} missing from dict.en`);
  }
});

test("the track duplicates the set so the loop is seamless", () => {
  const html = readLegal("index.html");
  const occurrences = (html.match(/data-i18n="cat\.sports"/g) ?? []).length;
  assert.equal(occurrences, 2,
    "the category set must appear exactly twice — the CSS loop translates by -50%");
});

test("the duplicate half is hidden from assistive tech", () => {
  const html = readLegal("index.html");
  assert.match(html, /aria-hidden="true"[^>]*data-ticker-clone|data-ticker-clone[^>]*aria-hidden="true"/,
    "the cloned half must be aria-hidden so screen readers do not read it twice");
});

test("the ticker pauses on hover and on focus", () => {
  const css = readLegal("assets/css/site.css");
  assert.match(css, /\.ticker:hover[^{]*\{[^}]*animation-play-state:\s*paused/);
  assert.match(css, /focus-within[^{]*\{[^}]*animation-play-state:\s*paused/);
});

test("the ticker edges are masked into the canvas", () => {
  const css = readLegal("assets/css/site.css");
  assert.match(css, /mask-image|mask:/);
});

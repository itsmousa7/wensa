import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { nextIndex } from "../legal/assets/js/rotator.js";
import { ROTATIONS } from "../legal/assets/js/i18n.js";

test("the rotation index wraps", () => {
  assert.equal(nextIndex(0, 5), 1);
  assert.equal(nextIndex(4, 5), 0);
  assert.equal(nextIndex(0, 1), 0);
});

test("the hero markup has a rotator slot", () => {
  const html = readLegal("index.html");
  assert.match(html, /data-rotator/, "the hero needs a [data-rotator] element");
});

test("the slot ships a real first word so no-JS visitors see a full sentence", () => {
  const html = readLegal("index.html");
  const slot = html.match(/<[^>]*data-rotator[^>]*>([^<]*)</);
  assert.ok(slot, "could not find the rotator element");
  assert.ok(slot[1].trim().length > 0, "the rotator must contain server-rendered text");
  assert.equal(slot[1].trim(), ROTATIONS.ar[0],
    "the shipped word must be the first Arabic rotation so JS starts from a matching state");
});

test("the hero ships both store buttons with the exact live URLs", () => {
  const html = readLegal("index.html");
  assert.ok(html.includes("id6780271862"), "iOS App Store link missing");
  assert.ok(html.includes("id=app.wensa.mobile"), "Google Play link missing");
  assert.match(html, /data-store-cta="ios"/);
  assert.match(html, /data-store-cta="android"/);
});

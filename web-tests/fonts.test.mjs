import { test } from "node:test";
import assert from "node:assert/strict";
import { statSync } from "node:fs";
import { join } from "node:path";
import { LEGAL_DIR, legalExists } from "./helpers.mjs";

const REQUIRED = [
  "graphik-ar-medium.woff2",
  "graphik-ar-bold.woff2",
  "ibm-plex-sans-300.woff2",
  "ibm-plex-sans-400.woff2",
  "ibm-plex-sans-500.woff2",
  "ibm-plex-sans-600.woff2",
  "ibm-plex-sans-700.woff2",
];

for (const name of REQUIRED) {
  test(`font ${name} exists and is a real woff2`, () => {
    const rel = `assets/fonts/${name}`;
    assert.ok(legalExists(rel), `${rel} is missing`);
    const size = statSync(join(LEGAL_DIR, rel)).size;
    assert.ok(size > 4000, `${rel} is only ${size} bytes — conversion probably failed`);
  });
}

test("the duplicate and Arabic-less source faces are not shipped", () => {
  assert.ok(!legalExists("assets/fonts/graphik-extra-bold.woff2"),
    "graphik-extra-bold is byte-identical to bold — shipping it wastes a request");
  assert.ok(!legalExists("assets/fonts/ibm-bold.woff2"),
    "ibm-bold.ttf is IBM Plex Sans Condensed with no Arabic glyphs — not used");
});

import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, localRefs, legalExists, PAGES } from "./helpers.mjs";

const SOURCES = [...PAGES, "assets/css/base.css", "assets/css/site.css"];

test("every local asset referenced anywhere actually exists on disk", () => {
  const missing = [];
  for (const source of SOURCES) {
    for (const ref of localRefs(readLegal(source))) {
      // cleanUrls means /merchants and /privacy resolve to .html files.
      const candidates = [ref.replace(/^\//, ""), ref.replace(/^\//, "") + ".html"];
      if (!candidates.some(legalExists)) missing.push(`${source} -> ${ref}`);
    }
  }
  assert.deepEqual(missing, [], "broken local references");
});

test("no page references a file outside the deploy root", () => {
  for (const page of PAGES) {
    assert.ok(!readLegal(page).includes("../"),
      `${page} uses a parent-relative path, which will 404 once deployed`);
  }
});

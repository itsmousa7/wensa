import { test } from "node:test";
import assert from "node:assert/strict";
import { legalJson, legalExists } from "./helpers.mjs";

test("root no longer redirects to /privacy", () => {
  const cfg = legalJson("vercel.json");
  const redirects = cfg.redirects ?? [];
  const rootRedirect = redirects.find((r) => r.source === "/");
  assert.equal(rootRedirect, undefined, "the / -> /privacy redirect must be removed so / serves the landing page");
});

test("deep-link rewrites are preserved", () => {
  const cfg = legalJson("vercel.json");
  const sources = (cfg.rewrites ?? []).map((r) => r.source);
  assert.ok(sources.includes("/placeDetails"), "/placeDetails rewrite must survive");
  assert.ok(sources.includes("/eventDetails"), "/eventDetails rewrite must survive");
});

test("well-known headers are preserved", () => {
  const cfg = legalJson("vercel.json");
  const wellKnown = (cfg.headers ?? []).find((h) => h.source.startsWith("/.well-known"));
  assert.ok(wellKnown, "the /.well-known header block must survive");
  const keys = wellKnown.headers.map((h) => h.key);
  assert.ok(keys.includes("Content-Type"));
  assert.ok(keys.includes("Access-Control-Allow-Origin"));
});

test("cleanUrls stays on so /merchants resolves without .html", () => {
  assert.equal(legalJson("vercel.json").cleanUrls, true);
});

test("both marketing pages exist", () => {
  assert.ok(legalExists("index.html"), "index.html must exist");
  assert.ok(legalExists("merchants.html"), "merchants.html must exist");
});

test("legal pages are untouched and still present", () => {
  for (const f of ["privacy.html", "download.html", "open.html", "assets/inapp-redirect.js"]) {
    assert.ok(legalExists(f), `${f} must not be deleted`);
  }
});

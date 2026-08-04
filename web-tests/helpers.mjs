// Shared helpers for the marketing-site tests. These read the real deployed
// files from legal/ — the tests are assertions about what actually ships, not
// about a copy of it.
import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

export const LEGAL_DIR = join(dirname(fileURLToPath(import.meta.url)), "..", "legal");

export function readLegal(relPath) {
  return readFileSync(join(LEGAL_DIR, relPath), "utf8");
}

export function legalJson(relPath) {
  return JSON.parse(readLegal(relPath));
}

export function legalExists(relPath) {
  return existsSync(join(LEGAL_DIR, relPath));
}

// Every root-relative asset reference in a chunk of HTML or CSS: src="/x",
// href="/x", and url(/x). Absolute http(s) URLs, anchors, and data: URIs are
// excluded — only things that must exist on disk are returned.
export function localRefs(text) {
  const out = new Set();
  const patterns = [
    /(?:src|href)\s*=\s*["'](\/[^"'#?]+)["']/g,
    /url\(\s*["']?(\/[^"')?#]+)["']?\s*\)/g,
  ];
  for (const re of patterns) {
    let m;
    while ((m = re.exec(text)) !== null) out.add(m[1]);
  }
  return [...out];
}

// Every data-i18n key used in a chunk of HTML.
export function i18nKeys(html) {
  const out = new Set();
  const re = /data-i18n(?:-[a-z]+)?\s*=\s*["']([^"']+)["']/g;
  let m;
  while ((m = re.exec(html)) !== null) out.add(m[1]);
  return [...out];
}

export const PAGES = ["index.html", "merchants.html"];

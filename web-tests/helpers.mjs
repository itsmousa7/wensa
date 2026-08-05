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
//
// Two distinct attributes carry keys and they encode them differently:
//   data-i18n="key"                       -- the value IS the key.
//   data-i18n-attr="attr:key[,attr2:key2]" -- one or more "attr:key" pairs;
//     only the key half of each pair belongs in the dictionary. Matching
//     data-i18n-attr with the same plain regex as data-i18n would (wrongly)
//     extract "content:meta.home.desc" as a literal key.
export function i18nKeys(html) {
  const out = new Set();

  const attrRe = /data-i18n-attr\s*=\s*["']([^"']+)["']/g;
  let m;
  while ((m = attrRe.exec(html)) !== null) {
    for (const pair of m[1].split(",")) {
      const key = pair.split(":")[1]?.trim();
      if (key) out.add(key);
    }
  }

  // "data-i18n=" only — "data-i18n-attr=" never matches this because the
  // literal "-attr" sits between "data-i18n" and "=" for that attribute.
  const plainRe = /\bdata-i18n\s*=\s*["']([^"']+)["']/g;
  while ((m = plainRe.exec(html)) !== null) out.add(m[1]);

  return [...out];
}

export const PAGES = ["index.html", "merchants.html"];

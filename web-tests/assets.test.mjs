import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { readLegal, localRefs, legalExists, LEGAL_DIR, PAGES } from "./helpers.mjs";

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

// Browsers use an <img>'s width/height attributes (not its CSS width/height,
// which is set separately and controls the actual displayed size) purely to
// compute an intrinsic ASPECT RATIO, so they can reserve layout space before
// the file has downloaded and decoded. If the declared attributes describe a
// different aspect ratio than the file's real pixel dimensions, the reserved
// space has the wrong shape and the page jumps when the image finally decodes
// — a real CLS bug, worst of all on an eager/fetchpriority=high (LCP) image.
//
// This checks aspect-ratio equivalence, not literal magnitude equality: a few
// images on this site (screen-*.png, download-qr.png) are intentionally
// declared at half their real pixel size — same shape, exported at 2x so a
// retina display doesn't upscale them — and that is correct, not a bug, so
// asserting raw width/height equality would flag legitimate assets. Declared
// and real ratios are compared via cross-multiplication (declaredW * realH
// vs declaredH * realW) to avoid floating-point rounding entirely.
//
// Reads the PNG's IHDR chunk directly: byte 0 is the 8-byte PNG signature,
// bytes 8-11 are the chunk length, bytes 12-15 are "IHDR", bytes 16-19 are
// width and bytes 20-23 are height, both big-endian uint32.
function pngDimensions(absPath) {
  const buf = readFileSync(absPath);
  const width = buf.readUInt32BE(16);
  const height = buf.readUInt32BE(20);
  return { width, height };
}

test("declared <img> width/height attributes describe the real PNG's aspect ratio", () => {
  const mismatches = [];
  for (const page of PAGES) {
    const html = readLegal(page);
    const imgRe = /<img\b[^>]*>/g;
    let m;
    while ((m = imgRe.exec(html)) !== null) {
      const tag = m[0];
      const srcMatch = tag.match(/\bsrc\s*=\s*["'](\/[^"'#?]+)["']/);
      const widthMatch = tag.match(/\bwidth\s*=\s*["']?(\d+)["']?/);
      const heightMatch = tag.match(/\bheight\s*=\s*["']?(\d+)["']?/);
      if (!srcMatch || !widthMatch || !heightMatch) continue; // only local, sized images apply

      const relPath = srcMatch[1].replace(/^\//, "");
      if (!relPath.toLowerCase().endsWith(".png") || !legalExists(relPath)) continue; // only PNGs we can decode here

      const declaredWidth = Number(widthMatch[1]);
      const declaredHeight = Number(heightMatch[1]);
      const real = pngDimensions(join(LEGAL_DIR, relPath));

      if (declaredWidth * real.height !== declaredHeight * real.width) {
        mismatches.push(
          `${page} -> ${relPath}: declared ${declaredWidth}x${declaredHeight} (ratio ${(declaredWidth / declaredHeight).toFixed(3)}), ` +
          `real ${real.width}x${real.height} (ratio ${(real.width / real.height).toFixed(3)})`
        );
      }
    }
  }
  assert.deepEqual(mismatches, [],
    "declared width/height must describe the same aspect ratio as the file's real pixel dimensions, or the browser reserves the wrong shape and the image shifts layout when it decodes");
});

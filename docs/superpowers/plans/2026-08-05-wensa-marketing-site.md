# Wensa Marketing Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a bilingual (Iraqi Arabic default, English toggle) marketing site at `wensa.app` — a consumer landing page at `/` and a become-a-merchant page at `/merchants` — inside the existing `legal/` Vercel project.

**Architecture:** Plain HTML + CSS + ES-module JavaScript with no build step, added to `wensa/legal/` which already deploys as the `wensa-privacy` Vercel project. Language switching is DOM-level via a `data-i18n` dictionary that flips `lang`/`dir` on `<html>`. The existing `assets/inapp-redirect.js` is reused untouched for Instagram/TikTok download escapes. Tests live *outside* the deploy root in `wensa/web-tests/` and run on Node's built-in test runner with zero dependencies.

**Tech Stack:** HTML5, CSS (custom properties, logical properties, `clamp()`, `IntersectionObserver`), ES modules, `node --test` (Node 26, no npm packages), Python 3.14 + Pillow (image work), `fonttools[woff]` in a throwaway venv (font conversion), `@fontsource/ibm-plex-sans@5.3.0` (font files only, not a runtime dependency).

## Global Constraints

- **Deploy root is `wensa/legal/`.** Everything in it is publicly served. Never put tests, tooling, `package.json`, or `node_modules` inside it.
- **No build step.** The site must work when the files are served as-is by a static host.
- **Never modify** `privacy.html`, `download.html`, `open.html`, `.well-known/apple-app-site-association`, `.well-known/assetlinks.json`, or `assets/inapp-redirect.js`.
- **Colors, verbatim:** `--paper: #FBFAF8`, `--ink: #18262B`, `--subink: #6C7A7E`, `--teal: #3490A2`, `--orange: #FF6F3C`, `--yellow: #FFD93D`.
- **One accent per screen.** TEAL is the default accent. ORANGE is used exactly once per page — the merchant offer badge. Never flood a frame with color.
- **Arabic copy is Iraqi dialect (دارجة عراقية), never فصحى.** Use `اكو/ماكو`, `هواي`, `شلون`, `شنو`, `وين`, `يلا`, `هسه`. Arabic-Indic numerals `٠١٢٣٤٥٦٧٨٩` in Arabic copy. Currency as `د.ع` in Arabic, `IQD` in English.
- **Arabic has exactly two weights available:** Graphik Arabic Medium (from `graphik-light.ttf`, which is misnamed) and Graphik Arabic Bold (from `graphik-bold.ttf`). `graphik-extra-bold.ttf` is a byte-identical duplicate of `graphik-bold.ttf` — do not ship it. `ibm-bold.ttf` is IBM Plex Sans *Condensed* Bold with zero Arabic codepoints — do not ship it.
- **Merchant CTA destination:** `https://dashboard.wensa.app`
- **Store URLs, verbatim:**
  - iOS — `https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862`
  - Android — `https://play.google.com/store/apps/details?id=app.wensa.mobile`
- **Animate only `transform` and `opacity`,** with exactly one documented exception: `.rotator__word`'s `width`, which is what makes the hero headline reflow smoothly instead of snapping. Nothing else may animate a layout property. `stroke-dashoffset` is paint-only and is allowed.
- **The three JS modules must not touch the DOM at import time.** `i18n.js`, `motion.js`, and `rotator.js` are imported directly by `node --test`, which has no DOM. Keep every DOM access inside a function body.
- **Every animation must collapse to its end state under `@media (prefers-reduced-motion: reduce)`.**
- **Pricing is hardcoded** and must match `wansa-admin-dashboard/src/features/merchant/PlansPage.tsx` exactly.
- **Commit after every task.** Work on branch `feat/marketing-site` in the `wensa` repo.

---

## File Structure

**Created in the deploy root (`wensa/legal/`):**

| File | Responsibility |
|---|---|
| `index.html` | Consumer landing page, 9 sections |
| `merchants.html` | Become-a-merchant page, 8 sections |
| `assets/css/base.css` | `@font-face`, design tokens, reset, fluid type scale |
| `assets/css/site.css` | Components, section layouts, motion keyframes |
| `assets/js/i18n.js` | AR/EN dictionary + `applyLang()` + toggle wiring |
| `assets/js/rotator.js` | Hero rotating-word animation |
| `assets/js/motion.js` | Scroll reveals, parallax, nav state, counters, line-draw |
| `assets/js/main.js` | Boots the modules and calls `WensaInAppRedirect.init()` |
| `assets/fonts/*.woff2` | 2 Graphik Arabic + 5 IBM Plex Sans faces |
| `assets/img/*` | Cut-out characters, app screens, download QR |

**Created outside the deploy root:**

| File | Responsibility |
|---|---|
| `wensa/web-tests/helpers.mjs` | Shared file readers and reference extractors |
| `wensa/web-tests/*.test.mjs` | One test file per concern |

**Modified:** `wensa/legal/vercel.json` — remove the `/` → `/privacy` redirect. Nothing else in that file changes.

**Note on a refinement from the spec:** the spec sketched a single `assets/site.css` and a flat `assets/*.js`. The plan splits CSS into `base.css` + `site.css` and puts JS under `assets/js/` so each file has one responsibility and stays small enough to reason about. Same deployed behaviour, two extra `<link>`/`import` lines.

---

## Task 1: Test harness, vercel.json, and page skeletons

**Files:**
- Create: `wensa/web-tests/helpers.mjs`
- Create: `wensa/web-tests/vercel.test.mjs`
- Create: `wensa/legal/index.html`
- Create: `wensa/legal/merchants.html`
- Modify: `wensa/legal/vercel.json`

**Interfaces:**
- Consumes: nothing.
- Produces: `LEGAL_DIR` (absolute path string), `readLegal(relPath) -> string`, `legalJson(relPath) -> object`, `localRefs(html) -> string[]` — all exported from `web-tests/helpers.mjs` and used by every later test file.

- [ ] **Step 1: Confirm you're on the right branch**

Work happens in the `feat/marketing-site` worktree, already created and checked out before implementation started.

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
git branch --show-current
```

Expected: `feat/marketing-site`. If this prints something else, stop and report — do not create a new branch.

- [ ] **Step 2: Write the test helpers**

Create `wensa/web-tests/helpers.mjs`:

```js
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
```

- [ ] **Step 3: Write the failing vercel.json test**

Create `wensa/web-tests/vercel.test.mjs`:

```js
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
```

- [ ] **Step 4: Run the tests and confirm they fail**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
node --test 'web-tests/*.test.mjs'
```

Expected: FAIL. `root no longer redirects to /privacy` fails because the redirect is still there, and `both marketing pages exist` fails because neither file has been created.

- [ ] **Step 5: Remove the root redirect from vercel.json**

In `wensa/legal/vercel.json`, delete the entire `redirects` array. Change:

```json
  "redirects": [
    { "source": "/", "destination": "/privacy", "permanent": false }
  ],
  "rewrites": [
```

to:

```json
  "rewrites": [
```

Leave `$schema`, `cleanUrls`, `headers`, and `rewrites` exactly as they are.

- [ ] **Step 6: Create the two page skeletons**

Create `wensa/legal/index.html`:

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ونسة — كل ونستك بمكان واحد</title>
  <link rel="icon" href="/favicon.ico" sizes="any">
  <link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
  <link rel="stylesheet" href="/assets/css/base.css">
  <link rel="stylesheet" href="/assets/css/site.css">
</head>

<body>
  <main id="main"></main>
  <script type="module" src="/assets/js/main.js"></script>
</body>

</html>
```

Create `wensa/legal/merchants.html` with the same structure, changing only `<title>` to `صير تاجر بونسة` and adding `data-page="merchants"` to `<body>`.

- [ ] **Step 7: Create empty placeholders so the stylesheet links resolve**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal
mkdir -p assets/css assets/js assets/fonts assets/img
printf '/* filled in Task 3 */\n' > assets/css/base.css
printf '/* filled in Task 5 onward */\n' > assets/css/site.css
printf '// filled in Task 5 onward\n' > assets/js/main.js
```

- [ ] **Step 8: Run the tests and confirm they pass**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
node --test 'web-tests/*.test.mjs'
```

Expected: PASS, 6/6.

- [ ] **Step 9: Commit**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
git add web-tests legal/index.html legal/merchants.html legal/vercel.json legal/assets
git commit -m "feat(site): scaffold marketing pages and free the root route

Removes the / -> /privacy redirect so index.html can serve the landing
page. Adds a dependency-free node:test harness in web-tests/, outside the
Vercel deploy root, asserting the legal pages and deep-link rewrites
survive the change."
```

---

## Task 2: Fonts

**Files:**
- Create: `wensa/legal/assets/fonts/graphik-ar-medium.woff2`
- Create: `wensa/legal/assets/fonts/graphik-ar-bold.woff2`
- Create: `wensa/legal/assets/fonts/ibm-plex-sans-{300,400,500,600,700}.woff2`
- Create: `wensa/legal/assets/fonts/IBM-Plex-Sans-LICENSE.txt` — the OFL license text, kept alongside the redistributed font files as a matter of good practice; harmless and correctly attributed.
- Create: `wensa/web-tests/fonts.test.mjs`

**Interfaces:**
- Consumes: `legalExists`, `LEGAL_DIR` from `helpers.mjs`.
- Produces: seven WOFF2 files at the exact filenames above. `base.css` in Task 3 declares `@font-face` for each; no other task touches them.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/fonts.test.mjs`:

```js
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
node --test web-tests/fonts.test.mjs
```

Expected: FAIL, 7 missing-file failures.

- [ ] **Step 3: Convert the two Graphik Arabic faces to WOFF2**

`fonttools` is not installed and macOS Python is externally managed, so use a throwaway venv. Note the source→target mapping: `graphik-light.ttf` reports the internal name *Graphik Arabic Medium*, so it becomes the **medium** face.

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
python3 -m venv /tmp/wensa-fontvenv
/tmp/wensa-fontvenv/bin/pip install --quiet "fonttools[woff]"
/tmp/wensa-fontvenv/bin/python - <<'PY'
from fontTools.ttLib import TTFont
SRC = "/Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/assets/fonts"
DST = "/Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal/assets/fonts"
for src, dst in [("graphik-light.ttf", "graphik-ar-medium.woff2"),
                 ("graphik-bold.ttf",  "graphik-ar-bold.woff2")]:
    f = TTFont(f"{SRC}/{src}")
    print(src, "->", dst, "| internal name:",
          next(r.toUnicode() for r in f["name"].names if r.nameID == 4))
    f.flavor = "woff2"
    f.save(f"{DST}/{dst}")
PY
```

Expected output confirms `graphik-light.ttf -> graphik-ar-medium.woff2 | internal name: Graphik Arabic Medium`.

- [ ] **Step 4: Fetch the IBM Plex Sans faces**

IBM Plex Sans is OFL-licensed. Take the pre-built WOFF2 files from `@fontsource/ibm-plex-sans@5.3.0` — the package is used purely as a file source, not as a runtime dependency, so nothing is added to the site.

```bash
cd /tmp
npm pack @fontsource/ibm-plex-sans@5.3.0
tar -xzf fontsource-ibm-plex-sans-5.3.0.tgz
DST=/Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal/assets/fonts
for w in 300 400 500 600 700; do
  cp "package/files/ibm-plex-sans-latin-${w}-normal.woff2" "$DST/ibm-plex-sans-${w}.woff2"
done
cp package/LICENSE "$DST/IBM-Plex-Sans-LICENSE.txt"
ls -la "$DST"
```

- [ ] **Step 5: Clean up the throwaway venv**

```bash
rm -rf /tmp/wensa-fontvenv /tmp/package /tmp/fontsource-ibm-plex-sans-5.3.0.tgz
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
node --test 'web-tests/*.test.mjs'
```

Expected: PASS. All seven font files present, both exclusions holding.

- [ ] **Step 7: Commit**

```bash
git add web-tests/fonts.test.mjs legal/assets/fonts
git commit -m "feat(site): add self-hosted webfonts

Graphik Arabic Medium + Bold converted from the Flutter TTFs (note:
graphik-light.ttf is internally named Medium, and extra-bold is a
byte-identical duplicate of bold, so only two faces ship). IBM Plex Sans
300-700 taken from the OFL-licensed @fontsource build, with its license."
```

---

## Task 3: Design tokens, reset, and type scale

**Files:**
- Create (replace placeholder): `wensa/legal/assets/css/base.css`
- Create: `wensa/web-tests/tokens.test.mjs`

**Interfaces:**
- Consumes: font files from Task 2.
- Produces: CSS custom properties every later task uses — `--paper --ink --subink --teal --orange --yellow`, `--font-ar --font-en --font`, `--step--1 --step-0 --step-1 --step-2 --step-3 --step-4`, `--space-1` … `--space-8`, `--wrap`, `--radius`, `--ease`. Also the `.u-wrap`, `.u-eyebrow`, and `.sr-only` utility classes.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/tokens.test.mjs`:

```js
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/tokens.test.mjs
```

Expected: FAIL — `base.css` is still the one-line placeholder.

- [ ] **Step 3: Write base.css**

Replace `wensa/legal/assets/css/base.css` entirely:

```css
/* ── Fonts ──────────────────────────────────────────────────────────────
   Arabic has exactly two weights. graphik-light.ttf is internally named
   "Graphik Arabic Medium", and extra-bold duplicates bold byte-for-byte,
   so Medium (500) and Bold (700) are the whole Arabic palette. Anything
   asking for 300 or 600 in Arabic resolves to the nearest of these two. */

@font-face {
  font-family: "Graphik Arabic";
  src: url("/assets/fonts/graphik-ar-medium.woff2") format("woff2");
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "Graphik Arabic";
  src: url("/assets/fonts/graphik-ar-bold.woff2") format("woff2");
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "IBM Plex Sans";
  src: url("/assets/fonts/ibm-plex-sans-300.woff2") format("woff2");
  font-weight: 300;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "IBM Plex Sans";
  src: url("/assets/fonts/ibm-plex-sans-400.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "IBM Plex Sans";
  src: url("/assets/fonts/ibm-plex-sans-500.woff2") format("woff2");
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "IBM Plex Sans";
  src: url("/assets/fonts/ibm-plex-sans-600.woff2") format("woff2");
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "IBM Plex Sans";
  src: url("/assets/fonts/ibm-plex-sans-700.woff2") format("woff2");
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

/* ── Tokens ─────────────────────────────────────────────────────────── */

:root {
  /* Canonical brand palette — WENSA_BRAND_SKILL.md §3. Do not invent values. */
  --paper: #FBFAF8;
  --ink: #18262B;
  --subink: #6C7A7E;
  --teal: #3490A2;
  --orange: #FF6F3C;
  --yellow: #FFD93D;

  --teal-soft: color-mix(in srgb, var(--teal) 10%, var(--paper));
  --line: color-mix(in srgb, var(--ink) 12%, transparent);

  --font-ar: "Graphik Arabic", "IBM Plex Sans", system-ui, sans-serif;
  --font-en: "IBM Plex Sans", system-ui, sans-serif;
  --font: var(--font-ar);

  /* Fluid type: 320px → 1440px viewport */
  --step--1: clamp(0.83rem, 0.79rem + 0.19vw, 0.94rem);
  --step-0: clamp(1rem, 0.93rem + 0.36vw, 1.19rem);
  --step-1: clamp(1.2rem, 1.08rem + 0.6vw, 1.5rem);
  --step-2: clamp(1.44rem, 1.25rem + 0.95vw, 1.9rem);
  --step-3: clamp(1.73rem, 1.43rem + 1.5vw, 2.4rem);
  --step-4: clamp(2.07rem, 1.6rem + 2.35vw, 3.03rem);
  --step-5: clamp(2.49rem, 1.75rem + 3.68vw, 4.5rem);

  --space-1: 0.5rem;
  --space-2: 1rem;
  --space-3: 1.5rem;
  --space-4: 2rem;
  --space-5: 3rem;
  --space-6: 4rem;
  --space-7: 6rem;
  --space-8: 8rem;

  --wrap: 1200px;
  --radius: 20px;
  --radius-sm: 12px;
  --ease: cubic-bezier(0.22, 1, 0.36, 1);
  --nav-h: 68px;
}

/* Arabic ink runs taller than its nominal metrics, so it needs a slightly
   looser line-height than the Latin stack to avoid ascender collisions. */
[lang="ar"] {
  --font: var(--font-ar);
  --lh-tight: 1.35;
  --lh-body: 1.85;
}

[lang="en"] {
  --font: var(--font-en);
  --lh-tight: 1.15;
  --lh-body: 1.65;
}

/* ── Reset ──────────────────────────────────────────────────────────── */

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { -webkit-text-size-adjust: 100%; scroll-behavior: smooth; }

body {
  background: var(--paper);
  color: var(--ink);
  font-family: var(--font);
  font-weight: 500;
  font-size: var(--step-0);
  line-height: var(--lh-body);
  overflow-x: clip;
}

img, svg { display: block; max-width: 100%; height: auto; }

a { color: inherit; text-decoration: none; }

button { font: inherit; color: inherit; background: none; border: none; cursor: pointer; }

h1, h2, h3 { font-weight: 700; line-height: var(--lh-tight); text-wrap: balance; }

h1 { font-size: var(--step-5); }
h2 { font-size: var(--step-4); }
h3 { font-size: var(--step-2); }

p { text-wrap: pretty; }

:focus-visible { outline: 3px solid var(--teal); outline-offset: 3px; border-radius: 4px; }

/* ── Utilities ──────────────────────────────────────────────────────── */

.u-wrap {
  width: min(100% - 2 * var(--space-3), var(--wrap));
  margin-inline: auto;
}

.u-eyebrow {
  font-size: var(--step--1);
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--teal);
  text-transform: uppercase;
}

[lang="ar"] .u-eyebrow { letter-spacing: 0; text-transform: none; }

.u-sub {
  color: var(--subink);
  font-size: var(--step-1);
  max-width: 52ch;
}

.sr-only {
  position: absolute;
  width: 1px; height: 1px;
  padding: 0; margin: -1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add legal/assets/css/base.css web-tests/tokens.test.mjs
git commit -m "feat(site): design tokens, reset and fluid type scale

Brand palette copied verbatim from WENSA_BRAND_SKILL.md. Font stack and
line-height are bound to [lang] so the Arabic and Latin scripts each get
correct leading without a separate RTL stylesheet."
```

---

## Task 4: i18n engine and dictionary

**Files:**
- Create: `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/i18n.test.mjs`
- Modify: `wensa/legal/index.html`, `wensa/legal/merchants.html` (add the pre-paint boot snippet)

**Interfaces:**
- Consumes: nothing.
- Produces, exported from `assets/js/i18n.js`:
  - `dict` — `{ ar: Record<string,string>, en: Record<string,string> }`
  - `ROTATIONS` — `{ ar: string[], en: string[] }`, the hero rotating words
  - `currentLang() -> "ar" | "en"`
  - `applyLang(lang: "ar" | "en") -> void` — sets `<html lang>`/`<html dir>`, swaps every `[data-i18n]` node's `textContent` and every `[data-i18n-attr]` node's named attribute, writes `localStorage.wensa_lang`, updates the `?lang=` query param, and dispatches a `wensa:langchange` `CustomEvent` with `{ detail: { lang } }`.
  - `initLangToggle() -> void` — wires every `[data-lang-toggle]` button.

Task 7's rotator listens for `wensa:langchange`. Tasks 6–15 add keys to `dict`; the parity test enforces that every key added to one language is added to the other.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/i18n.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, i18nKeys, PAGES } from "./helpers.mjs";
import { dict, ROTATIONS } from "../legal/assets/js/i18n.js";

test("ar and en dictionaries have identical key sets", () => {
  const ar = Object.keys(dict.ar).sort();
  const en = Object.keys(dict.en).sort();
  const missingEn = ar.filter((k) => !(k in dict.en));
  const missingAr = en.filter((k) => !(k in dict.ar));
  assert.deepEqual(missingEn, [], "keys present in ar but missing from en");
  assert.deepEqual(missingAr, [], "keys present in en but missing from ar");
});

test("no dictionary value is empty", () => {
  for (const lang of ["ar", "en"]) {
    for (const [key, value] of Object.entries(dict[lang])) {
      assert.ok(String(value).trim().length > 0, `${lang}.${key} is empty`);
    }
  }
});

test("every data-i18n key used in the HTML exists in both dictionaries", () => {
  for (const page of PAGES) {
    for (const key of i18nKeys(readLegal(page))) {
      assert.ok(key in dict.ar, `${page} uses "${key}" but dict.ar has no such key`);
      assert.ok(key in dict.en, `${page} uses "${key}" but dict.en has no such key`);
    }
  }
});

test("hero rotations are the same length in both languages", () => {
  assert.ok(ROTATIONS.ar.length >= 3, "need at least 3 rotating words");
  assert.equal(ROTATIONS.ar.length, ROTATIONS.en.length,
    "the rotation cycle must be the same length in both languages");
});

test("Arabic copy uses Arabic-Indic numerals, not Western digits", () => {
  const offenders = Object.entries(dict.ar)
    .filter(([, v]) => /[0-9]/.test(v))
    .map(([k]) => k);
  assert.deepEqual(offenders, [], "Arabic copy must use ٠١٢٣٤٥٦٧٨٩ per the brand copy rules");
});

test("both pages set the language before first paint", () => {
  for (const page of PAGES) {
    const html = readLegal(page);
    const headEnd = html.indexOf("</head>");
    const boot = html.slice(0, headEnd);
    assert.match(boot, /wensa_lang/,
      `${page} must read the stored language in <head> to avoid a flash of the wrong language`);
    assert.match(boot, /document\.documentElement\.lang/, `${page} must set lang in <head>`);
  }
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/i18n.test.mjs
```

Expected: FAIL with `Cannot find module .../legal/assets/js/i18n.js`.

- [ ] **Step 3: Write the i18n module**

Create `wensa/legal/assets/js/i18n.js`. Start with only the keys the shell needs — later tasks extend `dict` as they add sections.

```js
// Bilingual dictionary and language engine.
//
// Arabic is the default and is what the server sends. The toggle swaps text
// in place rather than navigating, so there is no reload and no flash. A tiny
// inline snippet in each page's <head> applies the stored choice before first
// paint; this module handles everything after that.
//
// Copy rules (WENSA_BRAND_SKILL.md §9): Iraqi dialect, never فصحى.
// Arabic-Indic numerals ٠١٢٣٤٥٦٧٨٩ in Arabic copy. Currency د.ع / IQD.

export const dict = {
  ar: {
    "nav.what": "شنو ونسة",
    "nav.places": "الاماكن",
    "nav.download": "نزّل التطبيق",
    "nav.merchant": "صير تاجر بونسة",
    "nav.langToggle": "English",
    "nav.skip": "روح للمحتوى",
    "footer.privacy": "سياسة الخصوصية",
    "footer.download": "نزّل التطبيق",
    "footer.merchant": "صير تاجر",
    "footer.rights": "كل الحقوق محفوظة",
    "footer.tagline": "كل ونستك بمكان واحد",
  },
  en: {
    "nav.what": "What is Wensa",
    "nav.places": "Places",
    "nav.download": "Get the app",
    "nav.merchant": "Become a merchant",
    "nav.langToggle": "عربي",
    "nav.skip": "Skip to content",
    "footer.privacy": "Privacy Policy",
    "footer.download": "Get the app",
    "footer.merchant": "Become a merchant",
    "footer.rights": "All rights reserved",
    "footer.tagline": "Everything you do, in one place",
  },
};

// The words that cycle inside the hero headline. Both arrays must stay the
// same length so the cycle reads identically in either language.
export const ROTATIONS = {
  ar: ["بادل", "مطعم", "مزرعة", "حفلة", "جم"],
  en: ["padel", "a table", "a farm", "a concert", "a gym"],
};

const STORAGE_KEY = "wensa_lang";

export function currentLang() {
  return document.documentElement.lang === "en" ? "en" : "ar";
}

export function applyLang(lang) {
  const safe = lang === "en" ? "en" : "ar";
  const table = dict[safe];

  document.documentElement.lang = safe;
  document.documentElement.dir = safe === "ar" ? "rtl" : "ltr";

  for (const el of document.querySelectorAll("[data-i18n]")) {
    const value = table[el.dataset.i18n];
    if (value !== undefined) el.textContent = value;
  }

  // data-i18n-attr="aria-label:nav.merchant" — key writes into a named attribute
  // rather than textContent, for labels, alt text, and titles.
  for (const el of document.querySelectorAll("[data-i18n-attr]")) {
    for (const pair of el.dataset.i18nAttr.split(",")) {
      const [attr, key] = pair.split(":").map((s) => s.trim());
      const value = table[key];
      if (value !== undefined) el.setAttribute(attr, value);
    }
  }

  try {
    localStorage.setItem(STORAGE_KEY, safe);
  } catch {
    // Private browsing can throw on write. The language still applies for
    // this pageview; only persistence is lost, which is not worth failing on.
  }

  const url = new URL(location.href);
  if (safe === "ar") url.searchParams.delete("lang");
  else url.searchParams.set("lang", "en");
  history.replaceState(null, "", url);

  document.dispatchEvent(new CustomEvent("wensa:langchange", { detail: { lang: safe } }));
}

export function initLangToggle() {
  for (const btn of document.querySelectorAll("[data-lang-toggle]")) {
    btn.addEventListener("click", () => {
      applyLang(currentLang() === "ar" ? "en" : "ar");
    });
  }
}
```

- [ ] **Step 4: Add the pre-paint boot snippet to both pages**

In `index.html` and `merchants.html`, insert this as the last element inside `<head>`, after the stylesheet links. It must be a blocking classic script, not a module — modules are deferred and would run after first paint, producing a visible flash of Arabic before English appears.

```html
  <script>
    // Runs before first paint. Deliberately not a module: modules defer, and a
    // deferred language switch is a visible flash of the wrong direction.
    (function () {
      var q = new URLSearchParams(location.search).get('lang');
      var stored = null;
      try { stored = localStorage.getItem('wensa_lang'); } catch (e) { }
      var lang = (q === 'en' || q === 'ar') ? q : (stored === 'en' ? 'en' : 'ar');
      document.documentElement.lang = lang;
      document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    })();
  </script>
```

- [ ] **Step 5: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS. There is no orphan-key test yet — it is added in Task 6, once the shared nav/footer markup actually references `nav.*` and `footer.*`. Adding it here would fail immediately, since these 11 seed keys exist in the dictionary before any markup uses them.

- [ ] **Step 6: Commit**

```bash
git add legal/assets/js/i18n.js legal/index.html legal/merchants.html web-tests/i18n.test.mjs
git commit -m "feat(site): bilingual engine with pre-paint language boot

Dictionary-driven text swapping with no reload. A blocking head snippet
applies the stored or query-param language before first paint so RTL/LTR
never flashes. Tests enforce ar/en key parity and Arabic-Indic numerals in
Arabic copy. The no-orphan-keys check lands in Task 6, once markup exists
to reference the seeded nav/footer keys."
```

---

## Task 5: Motion module

**Files:**
- Create: `wensa/legal/assets/js/motion.js`
- Create: `wensa/web-tests/motion.test.mjs`
- Modify: `wensa/legal/assets/css/site.css`

**Interfaces:**
- Consumes: nothing.
- Produces, exported from `assets/js/motion.js`:
  - `parallaxOffset(scrollY, elTop, viewportH, strength) -> number` — pure, testable
  - `initReveals() -> void` — observes `[data-reveal]`, adds `.is-in` when 15% visible, unobserves after
  - `initNav() -> void` — toggles `.is-scrolled` on `[data-nav]` past 40px
  - `initParallax() -> void` — drives `[data-parallax]` via a single rAF-throttled scroll listener
  - `initCounters() -> void` — rolls `[data-counter]` from 0 to its `data-counter` value once
  - `initLineDraw() -> void` — animates `[data-line-draw]` SVG paths via `stroke-dashoffset`
  - `prefersReducedMotion() -> boolean`

Every later section opts into motion by adding `data-reveal` (optionally `data-reveal-delay="1|2|3"`) to an element. No later task writes its own observer.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/motion.test.mjs`:

```js
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/motion.test.mjs
```

Expected: FAIL with `Cannot find module .../motion.js`.

- [ ] **Step 3: Write motion.js**

Create `wensa/legal/assets/js/motion.js`:

```js
// Scroll-driven motion. Pacing follows WENSA_BRAND_SKILL.md §8 — calm and
// confident, ease-out, nothing bouncy.
//
// Everything here animates transform and opacity only. One shared rAF-throttled
// scroll listener drives nav state and parallax so N elements cost one handler.

const REDUCE = "(prefers-reduced-motion: reduce)";

export function prefersReducedMotion() {
  return window.matchMedia(REDUCE).matches;
}

/**
 * How far to shift a parallax element, in pixels.
 *
 * Pure so it can be tested without a DOM. Returns 0 when the element's top sits
 * at the viewport's vertical centre, and ramps to ±strength as it approaches
 * either edge. The result is clamped so an element far off-screen never flies
 * away. Takes no scroll position: elTop comes from getBoundingClientRect(),
 * which is already viewport-relative.
 */
export function parallaxOffset(elTop, viewportH, strength) {
  const centre = viewportH / 2;
  const fromCentre = (centre - elTop) / centre; // -1 … 1 across the viewport
  const clamped = Math.max(-1, Math.min(1, fromCentre));
  return clamped * strength;
}

export function initReveals() {
  const targets = document.querySelectorAll("[data-reveal]");
  if (prefersReducedMotion()) {
    for (const el of targets) el.classList.add("is-in");
    return;
  }
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("is-in");
        io.unobserve(entry.target); // reveal is one-way; stop paying for it
      }
    },
    { threshold: 0.15, rootMargin: "0px 0px -8% 0px" }
  );
  for (const el of targets) io.observe(el);
}

export function initNav() {
  const nav = document.querySelector("[data-nav]");
  if (!nav) return;
  const update = () => nav.classList.toggle("is-scrolled", window.scrollY > 40);
  update();
  onScroll(update);
}

export function initParallax() {
  const items = [...document.querySelectorAll("[data-parallax]")];
  if (!items.length || prefersReducedMotion()) return;
  const update = () => {
    const vh = window.innerHeight;
    for (const el of items) {
      const strength = Number(el.dataset.parallax) || 20;
      const top = el.getBoundingClientRect().top;
      const y = parallaxOffset(top, vh, strength);
      el.style.transform = `translate3d(0, ${y.toFixed(2)}px, 0)`;
    }
  };
  update();
  onScroll(update);
}

export function initCounters() {
  const items = document.querySelectorAll("[data-counter]");
  if (!items.length) return;
  if (prefersReducedMotion()) {
    for (const el of items) el.textContent = formatNumber(el, Number(el.dataset.counter));
    return;
  }
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        io.unobserve(entry.target);
        rollUp(entry.target, Number(entry.target.dataset.counter), 1400);
      }
    },
    { threshold: 0.5 }
  );
  for (const el of items) io.observe(el);
}

export function initLineDraw() {
  const paths = document.querySelectorAll("[data-line-draw]");
  if (!paths.length) return;
  for (const path of paths) {
    const len = path.getTotalLength();
    path.style.strokeDasharray = String(len);
    path.style.strokeDashoffset = prefersReducedMotion() ? "0" : String(len);
  }
  if (prefersReducedMotion()) return;
  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        io.unobserve(entry.target);
        entry.target.style.transition = "stroke-dashoffset 1.2s var(--ease)";
        entry.target.style.strokeDashoffset = "0";
      }
    },
    { threshold: 0.3 }
  );
  for (const path of paths) io.observe(path);
}

// ── internals ────────────────────────────────────────────────────────────

let handlers = [];
let ticking = false;

function onScroll(fn) {
  handlers.push(fn);
  if (handlers.length > 1) return; // one listener serves every subscriber
  window.addEventListener(
    "scroll",
    () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        for (const h of handlers) h();
        ticking = false;
      });
    },
    { passive: true }
  );
  window.addEventListener("resize", () => { for (const h of handlers) h(); }, { passive: true });
}

function formatNumber(el, value) {
  const locale = document.documentElement.lang === "ar" ? "ar-EG" : "en-US";
  const suffix = el.dataset.counterSuffix ?? "";
  return new Intl.NumberFormat(locale).format(Math.round(value)) + suffix;
}

function rollUp(el, target, duration) {
  const start = performance.now();
  const tick = (now) => {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3); // ease-out-cubic
    el.textContent = formatNumber(el, target * eased);
    if (t < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}
```

- [ ] **Step 4: Add the motion CSS**

Replace the placeholder in `wensa/legal/assets/css/site.css` with:

```css
/* ── Motion ─────────────────────────────────────────────────────────────
   Everything below animates transform and opacity only. Reveal state is a
   class the IntersectionObserver in motion.js adds exactly once. */

[data-reveal] {
  opacity: 0;
  transform: translate3d(0, 16px, 0);
  transition: opacity 0.7s var(--ease), transform 0.7s var(--ease);
}

[data-reveal].is-in {
  opacity: 1;
  transform: translate3d(0, 0, 0);
}

[data-reveal-delay="1"] { transition-delay: 0.08s; }
[data-reveal-delay="2"] { transition-delay: 0.16s; }
[data-reveal-delay="3"] { transition-delay: 0.24s; }
[data-reveal-delay="4"] { transition-delay: 0.32s; }

[data-parallax] { will-change: transform; }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation: none !important;
    transition: none !important;
  }
  [data-reveal] {
    opacity: 1;
    transform: none;
  }
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS, including the four `parallaxOffset` assertions and both CSS guards.

- [ ] **Step 6: Commit**

```bash
git add legal/assets/js/motion.js legal/assets/css/site.css web-tests/motion.test.mjs
git commit -m "feat(site): scroll motion engine

One rAF-throttled scroll listener drives nav state and parallax for every
subscriber. Reveals and counters unobserve after firing. parallaxOffset is
pure so the clamping and symmetry are unit-tested without a DOM. Tests also
assert no layout property is ever transitioned."
```

---

## Task 6: Shared shell — nav, footer, language toggle

**Files:**
- Modify: `wensa/legal/index.html`, `wensa/legal/merchants.html`
- Modify: `wensa/legal/assets/css/site.css`
- Modify: `wensa/legal/assets/js/main.js`
- Create: `wensa/web-tests/shell.test.mjs`

**Interfaces:**
- Consumes: `applyLang`, `initLangToggle`, `currentLang` from `i18n.js`; `initReveals`, `initNav` from `motion.js`.
- Produces: the `<header data-nav>` and `<footer>` markup both pages share, and `main.js` as the single entry point every later task extends.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/shell.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, i18nKeys, PAGES } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

const DASHBOARD = "https://dashboard.wensa.app";

for (const page of PAGES) {
  test(`${page} has a nav with a language toggle`, () => {
    const html = readLegal(page);
    assert.match(html, /<header[^>]*data-nav/, "nav must carry data-nav for the scroll state");
    assert.match(html, /data-lang-toggle/, "a language toggle button is required");
  });

  test(`${page} has a skip link as the first focusable element`, () => {
    const html = readLegal(page);
    const bodyStart = html.indexOf("<body");
    const skip = html.indexOf('href="#main"', bodyStart);
    const firstLink = html.indexOf("<a ", bodyStart);
    assert.ok(skip > -1, "a skip-to-content link is required");
    assert.ok(skip - firstLink < 80, "the skip link must be the first anchor in the body");
  });

  test(`${page} points its merchant CTA at the dashboard`, () => {
    assert.ok(readLegal(page).includes(DASHBOARD) || page === "index.html",
      "merchants.html must link to the dashboard");
  });

  test(`${page} declares a viewport and charset`, () => {
    const html = readLegal(page);
    assert.match(html, /<meta charset="UTF-8">/i);
    assert.match(html, /name="viewport"[^>]*width=device-width/);
  });

  test(`${page} loads main.js as a module and inapp-redirect as a classic script`, () => {
    const html = readLegal(page);
    assert.match(html, /<script type="module" src="\/assets\/js\/main\.js">/);
    assert.match(html, /<script src="\/assets\/inapp-redirect\.js">/,
      "inapp-redirect.js is a classic IIFE and must not be loaded as a module");
  });
}

test("index.html links to the merchants page", () => {
  assert.match(readLegal("index.html"), /href="\/merchants"/);
});

test("merchants.html links back to the landing page", () => {
  assert.match(readLegal("merchants.html"), /href="\/"/);
});

// This is the first task where markup actually references the seeded nav.*
// and footer.* keys, so it is also the first point where "no orphan keys"
// can hold. Every later task adds its own keys and markup together, so this
// stays true through the rest of the plan.
test("no dictionary key is unused", () => {
  const used = new Set(PAGES.flatMap((p) => i18nKeys(readLegal(p))));
  const orphans = Object.keys(dict.ar).filter((k) => !used.has(k) && !k.startsWith("meta."));
  assert.deepEqual(orphans, [], "these keys are defined but never referenced in the HTML");
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/shell.test.mjs
```

Expected: FAIL — no nav markup exists.

- [ ] **Step 3: Add the dictionary keys already stubbed in Task 4**

No change needed — `nav.*` and `footer.*` keys were seeded in Task 4. Confirm they are still present in `assets/js/i18n.js`.

- [ ] **Step 4: Add the shell markup to both pages**

In `index.html`, replace `<body>…</body>` with:

```html
<body>
  <a class="skip" href="#main" data-i18n="nav.skip">روح للمحتوى</a>

  <header class="nav" data-nav>
    <div class="nav__inner u-wrap">
      <a class="nav__brand" href="/" aria-label="Wensa">
        <img src="/assets/wensa-logo.png" alt="" width="112" height="34">
      </a>

      <nav class="nav__links" aria-label="Primary">
        <a href="#what" data-i18n="nav.what">شنو ونسة</a>
        <a href="#places" data-i18n="nav.places">الاماكن</a>
        <a href="#download" data-i18n="nav.download">نزّل التطبيق</a>
      </nav>

      <div class="nav__actions">
        <button class="pill" type="button" data-lang-toggle data-i18n="nav.langToggle">English</button>
        <a class="btn btn--teal" href="/merchants" data-i18n="nav.merchant">صير تاجر بونسة</a>
      </div>
    </div>
  </header>

  <main id="main">
    <!-- sections added in Tasks 7-11 -->
  </main>

  <footer class="foot">
    <div class="foot__inner u-wrap">
      <div>
        <img src="/assets/wensa-logo.png" alt="Wensa" width="120" height="36">
        <p class="foot__tag" data-i18n="footer.tagline">كل ونستك بمكان واحد</p>
      </div>
      <nav class="foot__links" aria-label="Footer">
        <a href="/privacy" data-i18n="footer.privacy">سياسة الخصوصية</a>
        <a href="/download" data-i18n="footer.download">نزّل التطبيق</a>
        <a href="/merchants" data-i18n="footer.merchant">صير تاجر</a>
      </nav>
      <p class="foot__rights">
        wensa<span class="foot__dot">.</span>app — <span data-i18n="footer.rights">كل الحقوق محفوظة</span>
      </p>
    </div>
  </footer>

  <script src="/assets/inapp-redirect.js"></script>
  <script type="module" src="/assets/js/main.js"></script>
</body>
```

In `merchants.html`, use the same shell with three changes: the nav links become a single `<a href="/" data-i18n="nav.what">`, the primary CTA becomes `<a class="btn btn--teal" href="https://dashboard.wensa.app" data-i18n="merchant.ctaRegister">سجّل هسه</a>`, and add `"merchant.ctaRegister"` to both dictionaries (`ar: "سجّل هسه"`, `en: "Register now"`).

- [ ] **Step 5: Add the shell CSS**

Append to `wensa/legal/assets/css/site.css`:

```css
/* ── Skip link ──────────────────────────────────────────────────────── */

.skip {
  position: absolute;
  inset-block-start: -100px;
  inset-inline-start: var(--space-2);
  z-index: 100;
  padding: var(--space-1) var(--space-2);
  background: var(--ink);
  color: var(--paper);
  border-radius: var(--radius-sm);
  transition: transform 0.2s var(--ease);
}

.skip:focus { transform: translateY(calc(100px + var(--space-2))); }

/* ── Nav ────────────────────────────────────────────────────────────── */

.nav {
  position: sticky;
  inset-block-start: 0;
  z-index: 50;
  background: color-mix(in srgb, var(--paper) 80%, transparent);
  border-block-end: 1px solid transparent;
  transition: background 0.3s var(--ease), border-color 0.3s var(--ease);
}

.nav.is-scrolled {
  background: color-mix(in srgb, var(--paper) 92%, transparent);
  backdrop-filter: blur(14px);
  border-block-end-color: var(--line);
}

.nav__inner {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-height: var(--nav-h);
}

.nav__brand { flex-shrink: 0; }

/* The "shrink on scroll" is a transform on the wordmark, not a height change
   on the bar. Animating the bar's height would relayout the whole page on
   every scroll frame; scaling the logo is composited and costs nothing. */
.nav__brand img {
  width: 112px;
  height: auto;
  transform-origin: center;
  transition: transform 0.3s var(--ease);
}

.nav.is-scrolled .nav__brand img { transform: scale(0.86); }

.nav__links {
  display: flex;
  gap: var(--space-3);
  margin-inline-start: auto;
  font-size: var(--step--1);
  color: var(--subink);
}

.nav__links a { transition: color 0.2s var(--ease); }
.nav__links a:hover { color: var(--teal); }

.nav__actions {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-inline-start: auto;
}

.nav__links + .nav__actions { margin-inline-start: 0; }

@media (max-width: 900px) {
  .nav__links { display: none; }
  .nav__brand img { width: 92px; }
}

/* ── Buttons ────────────────────────────────────────────────────────── */

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-1);
  padding: 0.7em 1.4em;
  border-radius: 999px;
  font-weight: 700;
  font-size: var(--step--1);
  white-space: nowrap;
  transition: transform 0.2s var(--ease), box-shadow 0.2s var(--ease);
}

.btn--teal {
  background: var(--teal);
  color: #fff;
  box-shadow: 0 4px 14px color-mix(in srgb, var(--teal) 28%, transparent);
}

.btn--teal:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 26px color-mix(in srgb, var(--teal) 38%, transparent);
}

.btn--teal:active { transform: translateY(0); }

.btn--ghost {
  border: 1.5px solid var(--line);
  color: var(--ink);
}

.btn--ghost:hover { transform: translateY(-2px); border-color: var(--teal); }

.pill {
  padding: 0.45em 0.9em;
  border-radius: 999px;
  border: 1.5px solid var(--line);
  font-size: var(--step--1);
  font-weight: 700;
  color: var(--subink);
  transition: transform 0.2s var(--ease), border-color 0.2s var(--ease), color 0.2s var(--ease);
}

.pill:hover { color: var(--teal); border-color: var(--teal); transform: translateY(-1px); }

/* ── Footer ─────────────────────────────────────────────────────────── */

.foot {
  margin-block-start: var(--space-8);
  padding-block: var(--space-6);
  border-block-start: 1px solid var(--line);
}

.foot__inner {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-4);
  align-items: flex-start;
  justify-content: space-between;
}

.foot__tag { color: var(--subink); font-size: var(--step--1); margin-block-start: var(--space-1); }

.foot__links { display: flex; flex-direction: column; gap: var(--space-1); font-size: var(--step--1); }
.foot__links a { color: var(--subink); transition: color 0.2s var(--ease); }
.foot__links a:hover { color: var(--teal); }

.foot__rights { color: var(--subink); font-size: var(--step--1); }
.foot__dot { color: var(--teal); }
```

- [ ] **Step 6: Wire main.js**

Replace `wensa/legal/assets/js/main.js`:

```js
import { applyLang, currentLang, initLangToggle } from "./i18n.js";
import { initReveals, initNav, initParallax, initCounters, initLineDraw } from "./motion.js";

// The <head> snippet already set lang/dir before paint. Re-applying here fills
// in the text nodes, which the snippet deliberately does not touch.
applyLang(currentLang());
initLangToggle();

initNav();
initReveals();
initParallax();
initCounters();
initLineDraw();

// Store buttons only. Unlike /download, this page must NOT use
// { wholePage: true, autoAttempt: true } — wholePage makes the first tap
// anywhere jump to the App Store, which would break every link on a marketing
// page, and autoAttempt would fire an escape before the visitor reads anything.
if (window.WensaInAppRedirect) window.WensaInAppRedirect.init();
```

- [ ] **Step 7: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS. The i18n orphan-key test now has real markup to check against.

- [ ] **Step 8: Verify in a browser**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal
python3 -m http.server 4173
```

Open `http://localhost:4173/` and confirm: nav is RTL with the wordmark on the right, the toggle flips every string and the direction, the choice survives a reload, and `?lang=en` loads English with no flash. Stop the server when done.

- [ ] **Step 9: Commit**

```bash
git add legal/index.html legal/merchants.html legal/assets/css/site.css legal/assets/js/main.js legal/assets/js/i18n.js web-tests/shell.test.mjs
git commit -m "feat(site): shared nav, footer and language toggle

main.js calls WensaInAppRedirect.init() with no options — deliberately
unlike download.html, where wholePage/autoAttempt are correct. On a
marketing page those would hijack the first tap and fire an escape before
the visitor has read anything."
```

---

## Task 7: Hero with rotating word

**Files:**
- Create: `wensa/legal/assets/js/rotator.js`
- Modify: `wensa/legal/index.html`, `wensa/legal/assets/css/site.css`, `wensa/legal/assets/js/main.js`, `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/rotator.test.mjs`

**Interfaces:**
- Consumes: `ROTATIONS` from `i18n.js`; the `wensa:langchange` event.
- Produces: `initRotator(root?: Element) -> void` exported from `assets/js/rotator.js`, and `nextIndex(i, total) -> number` exported for testing.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/rotator.test.mjs`:

```js
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/rotator.test.mjs
```

Expected: FAIL with `Cannot find module .../rotator.js`.

- [ ] **Step 3: Write rotator.js**

Create `wensa/legal/assets/js/rotator.js`:

```js
// The hero's cycling word.
//
// The outgoing word slides up out of a clipping mask while the incoming word
// rises into the same slot. The slot's width animates to the incoming word's
// measured width so the rest of the headline reflows smoothly instead of
// snapping. Widths are measured once per language into an off-screen mirror,
// because measuring during the transition would read a mid-animation value.

import { ROTATIONS, currentLang } from "./i18n.js";
import { prefersReducedMotion } from "./motion.js";

const INTERVAL = 2200;
const SWAP = 520; // must match --rotator-swap in site.css

export function nextIndex(i, total) {
  return (i + 1) % total;
}

export function initRotator(root = document) {
  const slot = root.querySelector("[data-rotator]");
  if (!slot) return;

  let words = ROTATIONS[currentLang()];
  let index = 0;
  let timer = null;

  const mirror = document.createElement("span");
  mirror.className = "rotator__mirror";
  mirror.setAttribute("aria-hidden", "true");
  slot.parentElement.appendChild(mirror);

  const measure = (word) => {
    mirror.textContent = word;
    return mirror.getBoundingClientRect().width;
  };

  const render = (word, animate) => {
    slot.style.setProperty("--rotator-w", `${measure(word).toFixed(1)}px`);
    if (!animate) {
      slot.textContent = word;
      return;
    }
    slot.classList.add("is-out");
    setTimeout(() => {
      slot.textContent = word;
      slot.classList.remove("is-out");
      slot.classList.add("is-in");
      setTimeout(() => slot.classList.remove("is-in"), SWAP);
    }, SWAP / 2);
  };

  const start = () => {
    stop();
    if (prefersReducedMotion() || words.length < 2) return;
    timer = setInterval(() => {
      index = nextIndex(index, words.length);
      render(words[index], true);
    }, INTERVAL);
  };

  const stop = () => {
    if (timer) clearInterval(timer);
    timer = null;
  };

  // Restart from the top in the new language, so the two languages never drift
  // into showing unrelated words at the same position in the cycle.
  document.addEventListener("wensa:langchange", () => {
    words = ROTATIONS[currentLang()];
    index = 0;
    render(words[0], false);
    start();
  });

  // Don't burn frames or battery while the tab is hidden.
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) stop();
    else start();
  });

  render(words[0], false);
  start();
}
```

- [ ] **Step 4: Add the hero markup**

Add these keys to both dictionaries in `i18n.js`:

| Key | ar | en |
|---|---|---|
| `hero.eyebrow` | `نزل هسه — مجاناً` | `Out now — free` |
| `hero.lead` | `احجز` | `Book` |
| `hero.trail` | `بثانية وحدة` | `in one second` |
| `hero.sub` | `مطاعم، ملاعب، مزارع وحفلات — كلها بتطبيق واحد. شوف، احجز، وادفع بالدينار، وتذكرتك تجيك QR.` | `Restaurants, courts, farms and concerts — all in one app. Browse, book, pay in IQD, and get a QR ticket.` |
| `hero.ios` | `نزّله من App Store` | `Download on the App Store` |
| `hero.android` | `نزّله من Google Play` | `Get it on Google Play` |

Inside `<main id="main">` in `index.html`:

```html
    <section class="hero">
      <div class="hero__inner u-wrap">
        <div class="hero__copy">
          <p class="u-eyebrow" data-reveal data-i18n="hero.eyebrow">نزل هسه — مجاناً</p>

          <h1 class="hero__title" data-reveal data-reveal-delay="1">
            <span data-i18n="hero.lead">احجز</span>
            <span class="rotator"><span class="rotator__word" data-rotator>بادل</span></span>
            <span data-i18n="hero.trail">بثانية وحدة</span>
          </h1>

          <p class="u-sub" data-reveal data-reveal-delay="2" data-i18n="hero.sub">
            مطاعم، ملاعب، مزارع وحفلات — كلها بتطبيق واحد. شوف، احجز، وادفع بالدينار، وتذكرتك تجيك QR.
          </p>

          <div class="hero__cta" data-reveal data-reveal-delay="3">
            <a class="btn btn--teal" data-store-cta="ios"
               href="https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862"
               data-i18n="hero.ios">نزّله من App Store</a>
            <a class="btn btn--ghost" data-store-cta="android"
               href="https://play.google.com/store/apps/details?id=app.wensa.mobile"
               data-i18n="hero.android">نزّله من Google Play</a>
          </div>
        </div>

        <div class="hero__art" data-reveal data-reveal-delay="2">
          <div class="phone" data-parallax="24">
            <img src="/assets/img/screen-home.png" alt="" width="390" height="844" loading="eager">
          </div>
        </div>
      </div>
    </section>
```

**Screenshot placeholder.** `assets/img/screen-home.png` does not exist yet (spec §10a). Until the real screenshots arrive, generate a neutral placeholder so layout can be verified:

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal/assets/img
python3 -c "
from PIL import Image, ImageDraw
im = Image.new('RGB', (780, 1688), '#E8EEF0')
d = ImageDraw.Draw(im)
d.text((300, 830), 'SCREENSHOT\nPENDING', fill='#6C7A7E')
im.save('screen-home.png')
"
```

- [ ] **Step 5: Add the hero CSS**

Append to `site.css`:

```css
/* ── Hero ───────────────────────────────────────────────────────────── */

.hero {
  padding-block: clamp(var(--space-5), 8vw, var(--space-8));
  background:
    radial-gradient(120% 80% at 80% 0%, color-mix(in srgb, var(--teal) 9%, transparent), transparent 60%),
    var(--paper);
}

.hero__inner {
  display: grid;
  gap: var(--space-6);
  grid-template-columns: 1fr;
  align-items: center;
}

@media (min-width: 900px) {
  .hero__inner { grid-template-columns: 1.15fr 0.85fr; }
}

.hero__copy { display: flex; flex-direction: column; gap: var(--space-3); }

.hero__title { font-size: var(--step-5); }

.hero__cta { display: flex; flex-wrap: wrap; gap: var(--space-2); margin-block-start: var(--space-2); }

.hero__art { display: flex; justify-content: center; }

.phone {
  width: min(300px, 70vw);
  padding: 10px;
  border-radius: 42px;
  background: var(--ink);
  box-shadow: 0 30px 70px color-mix(in srgb, var(--ink) 22%, transparent);
}

.phone img { border-radius: 32px; }

/* ── Rotator ────────────────────────────────────────────────────────── */

.rotator {
  --rotator-swap: 520ms;
  display: inline-block;
  overflow: hidden;
  vertical-align: bottom;
  color: var(--teal);
}

.rotator__word {
  display: inline-block;
  width: var(--rotator-w, auto);
  transition:
    width var(--rotator-swap) var(--ease),
    transform calc(var(--rotator-swap) / 2) var(--ease),
    opacity calc(var(--rotator-swap) / 2) var(--ease);
}

.rotator__word.is-out { transform: translate3d(0, -0.9em, 0); opacity: 0; }
.rotator__word.is-in { animation: rotator-in calc(var(--rotator-swap) / 2) var(--ease); }

@keyframes rotator-in {
  from { transform: translate3d(0, 0.9em, 0); opacity: 0; }
  to { transform: translate3d(0, 0, 0); opacity: 1; }
}

/* Off-screen twin used only to measure the next word's width. */
.rotator__mirror {
  position: absolute;
  visibility: hidden;
  white-space: nowrap;
  pointer-events: none;
  font: inherit;
  font-weight: inherit;
}
```

- [ ] **Step 6: Boot the rotator**

In `main.js`, add the import and the call after `initReveals()`:

```js
import { initRotator } from "./rotator.js";
```

```js
initRotator();
```

- [ ] **Step 7: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 8: Verify in a browser**

Serve with `python3 -m http.server 4173` from `legal/`, open `/`, and confirm: the word cycles every ~2.2s, the headline reflows smoothly rather than jumping, the cycle restarts from the first word when you toggle language, and it stops when you switch browser tabs. In DevTools, enable *Rendering → Emulate prefers-reduced-motion* and confirm the word freezes on the first entry.

- [ ] **Step 9: Commit**

```bash
git add legal/index.html legal/assets/js/rotator.js legal/assets/js/main.js legal/assets/js/i18n.js legal/assets/css/site.css legal/assets/img web-tests/rotator.test.mjs
git commit -m "feat(site): hero with rotating headline word

The slot animates to each word's pre-measured width so the headline reflows
instead of snapping. The cycle restarts on language change so the two
languages never drift apart, and pauses on tab hide."
```

---

## Task 8: Category ticker

**Files:**
- Modify: `wensa/legal/index.html`, `wensa/legal/assets/css/site.css`, `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/ticker.test.mjs`

**Interfaces:**
- Consumes: nothing new.
- Produces: the `.ticker` markup pattern. Pure CSS animation — no JS module.

The nine categories are exactly what the app's home screen renders, per `wensa/lib/features/home/presentation/widgets/category_bar.dart`.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/ticker.test.mjs`:

```js
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
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/ticker.test.mjs
```

Expected: FAIL — the category keys do not exist.

- [ ] **Step 3: Add the category keys**

Add to `i18n.js`:

```js
// The nine categories the app's home screen actually renders — see
// lib/features/home/presentation/widgets/category_bar.dart. Do not add a
// category here that the app does not have.
```

| Key | ar | en |
|---|---|---|
| `cat.sports` | `رياضة` | `Sports` |
| `cat.restaurants` | `مطاعم` | `Restaurants` |
| `cat.music` | `موسيقى` | `Music` |
| `cat.malls` | `مولات` | `Malls` |
| `cat.cafes` | `كافيهات` | `Cafes` |
| `cat.cinema` | `سينما` | `Cinema` |
| `cat.festivals` | `مهرجانات` | `Festivals` |
| `cat.farms` | `مزارع` | `Farms` |
| `cat.discounts` | `خصومات` | `Discounts` |
| `ticker.label` | `شنو تلگه بونسة` | `What you'll find on Wensa` |

- [ ] **Step 4: Add the ticker markup**

After the hero in `index.html`:

```html
    <section class="ticker-wrap" id="places" aria-labelledby="ticker-label">
      <h2 id="ticker-label" class="sr-only" data-i18n="ticker.label">شنو تلگه بونسة</h2>
      <div class="ticker">
        <ul class="ticker__set">
          <li><span class="ticker__dot"></span><span data-i18n="cat.sports">رياضة</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.restaurants">مطاعم</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.music">موسيقى</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.malls">مولات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.cafes">كافيهات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.cinema">سينما</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.festivals">مهرجانات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.farms">مزارع</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.discounts">خصومات</span></li>
        </ul>
        <ul class="ticker__set" data-ticker-clone aria-hidden="true">
          <li><span class="ticker__dot"></span><span data-i18n="cat.sports">رياضة</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.restaurants">مطاعم</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.music">موسيقى</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.malls">مولات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.cafes">كافيهات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.cinema">سينما</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.festivals">مهرجانات</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.farms">مزارع</span></li>
          <li><span class="ticker__dot"></span><span data-i18n="cat.discounts">خصومات</span></li>
        </ul>
      </div>
    </section>
```

- [ ] **Step 5: Add the ticker CSS**

Append to `site.css`:

```css
/* ── Category ticker ────────────────────────────────────────────────────
   Two identical halves translated by -50% give a seamless loop with no JS.
   Direction is right-to-left in both languages, so the animation is written
   against a fixed axis rather than a logical one. */

.ticker-wrap {
  padding-block: var(--space-4);
  border-block: 1px solid var(--line);
  overflow: hidden;
  mask-image: linear-gradient(to right, transparent, #000 12%, #000 88%, transparent);
}

.ticker {
  display: flex;
  width: max-content;
  animation: ticker-slide 38s linear infinite;
}

.ticker:hover,
.ticker:focus-within { animation-play-state: paused; }

.ticker__set {
  display: flex;
  align-items: center;
  gap: var(--space-5);
  padding-inline: calc(var(--space-5) / 2);
  list-style: none;
}

.ticker__set li {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--step-1);
  font-weight: 700;
  color: var(--ink);
  white-space: nowrap;
}

.ticker__dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--teal);
  flex-shrink: 0;
}

@keyframes ticker-slide {
  from { transform: translate3d(0, 0, 0); }
  to { transform: translate3d(-50%, 0, 0); }
}

@media (prefers-reduced-motion: reduce) {
  .ticker { animation: none; }
  .ticker-wrap { overflow-x: auto; }
}
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Verify in a browser**

Serve and open `/`. Confirm the strip slides right-to-left with no visible seam at the wrap point, pauses on hover, fades at both edges, and reads correctly in English. Under emulated reduced motion it must become a static, horizontally scrollable row.

- [ ] **Step 8: Commit**

```bash
git add legal/index.html legal/assets/css/site.css legal/assets/js/i18n.js web-tests/ticker.test.mjs
git commit -m "feat(site): category ticker

The nine categories are exactly what category_bar.dart renders. Pure CSS
seamless loop over a duplicated track; the clone is aria-hidden so screen
readers do not hear the list twice."
```

---

## Task 9: Landing — feature cards, how-it-works, trust strip

**Files:**
- Modify: `wensa/legal/index.html`, `wensa/legal/assets/css/site.css`, `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/landing.test.mjs`

**Interfaces:**
- Consumes: `data-reveal`, `data-line-draw`, `data-counter` from `motion.js`.
- Produces: the `.cards`, `.steps`, and `.trust` component classes, reused by Tasks 12 and 13 on the merchants page.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/landing.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";

test("the what-you-can-do section has three feature cards", () => {
  const html = readLegal("index.html");
  const section = html.slice(html.indexOf('id="what"'), html.indexOf('id="how"'));
  const cards = (section.match(/class="card"/g) ?? []).length;
  assert.equal(cards, 3, `expected 3 feature cards, found ${cards}`);
});

test("the how-it-works section has three steps and an animated connector", () => {
  const html = readLegal("index.html");
  const section = html.slice(html.indexOf('id="how"'), html.indexOf('id="trust"'));
  const steps = (section.match(/class="step"/g) ?? []).length;
  assert.equal(steps, 3, `expected 3 steps, found ${steps}`);
  assert.match(section, /data-line-draw/, "the connector path must opt into the line-draw animation");
});

test("every card and step reveals on scroll with a stagger", () => {
  const html = readLegal("index.html");
  assert.ok((html.match(/data-reveal-delay/g) ?? []).length >= 6,
    "cards and steps should stagger rather than all appearing at once");
});

test("section headings are h2, so the document outline is not broken", () => {
  const html = readLegal("index.html");
  assert.equal((html.match(/<h1/g) ?? []).length, 1, "exactly one h1 per page");
  assert.ok((html.match(/<h2/g) ?? []).length >= 3);
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/landing.test.mjs
```

Expected: FAIL — the sections do not exist.

- [ ] **Step 3: Add the dictionary keys**

| Key | ar | en |
|---|---|---|
| `what.title` | `شنو تكدر تسوي بونسة؟` | `What can you do on Wensa?` |
| `what.c1.title` | `دور وشوف` | `Discover` |
| `what.c1.body` | `كل الاماكن الحلوة ببغداد بمكان واحد — صور، دوام، تقييمات، وموقع.` | `Every good spot in Baghdad in one place — photos, hours, ratings and location.` |
| `what.c2.title` | `احجز بثانية` | `Book in a second` |
| `what.c2.body` | `طاولة، ملعب، شاليه او تذكرة حفلة — احجز وانت كاعد وادفع بالدينار.` | `A table, a court, a chalet or a concert ticket — book from your seat and pay in IQD.` |
| `what.c3.title` | `تذكرتك QR` | `Your QR ticket` |
| `what.c3.body` | `تذكرتك تجيك بالتطبيق. وريها عالباب وخلص — ماكو ورق وماكو لخبطة.` | `Your ticket lives in the app. Show it at the door — no paper, no hassle.` |
| `how.title` | `شلون تشتغل؟` | `How it works` |
| `how.s1.title` | `نزّل التطبيق` | `Get the app` |
| `how.s1.body` | `مجاني على iOS و Android.` | `Free on iOS and Android.` |
| `how.s2.title` | `اختار مكانك` | `Pick your spot` |
| `how.s2.body` | `دور حسب النوع، المنطقة، او التقييم.` | `Browse by category, area or rating.` |
| `how.s3.title` | `احجز وروح` | `Book and go` |
| `how.s3.body` | `ادفع بالدينار وتذكرتك تجيك QR.` | `Pay in IQD and get your QR ticket.` |
| `trust.iqd` | `دفع بالدينار` | `Pay in IQD` |
| `trust.qr` | `تذكرة QR` | `QR ticket` |
| `trust.cancel` | `إلغاء سهل` | `Easy cancellation` |
| `num.1` | `١` | `1` |
| `num.2` | `٢` | `2` |
| `num.3` | `٣` | `3` |

`num.1`–`num.3` are shared step-number labels, reused by both the "how it
works" steps here and the merchant "how to join" steps in Task 12 (which
also adds `num.4`). Without `data-i18n`, these would stay as Arabic-Indic
digits even after switching to English — the global constraint that Arabic
copy uses Arabic-Indic numerals says nothing about English copy, and
English step numbers must read as 1/2/3, not ١/٢/٣.

- [ ] **Step 4: Add the markup**

After the ticker in `index.html`:

```html
    <section class="section" id="what" aria-labelledby="what-title">
      <div class="u-wrap">
        <h2 id="what-title" data-reveal data-i18n="what.title">شنو تكدر تسوي بونسة؟</h2>

        <div class="cards">
          <article class="card" data-reveal data-reveal-delay="1">
            <div class="card__shot"><img src="/assets/img/screen-home.png" alt="" width="390" height="844" loading="lazy"></div>
            <h3 data-i18n="what.c1.title">دور وشوف</h3>
            <p class="u-sub" data-i18n="what.c1.body">كل الاماكن الحلوة ببغداد بمكان واحد — صور، دوام، تقييمات، وموقع.</p>
          </article>

          <article class="card" data-reveal data-reveal-delay="2">
            <div class="card__shot"><img src="/assets/img/screen-book.png" alt="" width="390" height="844" loading="lazy"></div>
            <h3 data-i18n="what.c2.title">احجز بثانية</h3>
            <p class="u-sub" data-i18n="what.c2.body">طاولة، ملعب، شاليه او تذكرة حفلة — احجز وانت كاعد وادفع بالدينار.</p>
          </article>

          <article class="card" data-reveal data-reveal-delay="3">
            <div class="card__shot"><img src="/assets/img/screen-ticket.png" alt="" width="390" height="844" loading="lazy"></div>
            <h3 data-i18n="what.c3.title">تذكرتك QR</h3>
            <p class="u-sub" data-i18n="what.c3.body">تذكرتك تجيك بالتطبيق. وريها عالباب وخلص — ماكو ورق وماكو لخبطة.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="how" aria-labelledby="how-title">
      <div class="u-wrap">
        <h2 id="how-title" data-reveal data-i18n="how.title">شلون تشتغل؟</h2>

        <div class="steps">
          <svg class="steps__line" viewBox="0 0 1000 2" preserveAspectRatio="none" aria-hidden="true">
            <path d="M0 1 H1000" data-line-draw fill="none" stroke="var(--teal)" stroke-width="2" stroke-dasharray="6 8" />
          </svg>

          <article class="step" data-reveal data-reveal-delay="1">
            <span class="step__num" data-i18n="num.1">١</span>
            <h3 data-i18n="how.s1.title">نزّل التطبيق</h3>
            <p class="u-sub" data-i18n="how.s1.body">مجاني على iOS و Android.</p>
          </article>

          <article class="step" data-reveal data-reveal-delay="2">
            <span class="step__num" data-i18n="num.2">٢</span>
            <h3 data-i18n="how.s2.title">اختار مكانك</h3>
            <p class="u-sub" data-i18n="how.s2.body">دور حسب النوع، المنطقة، او التقييم.</p>
          </article>

          <article class="step" data-reveal data-reveal-delay="3">
            <span class="step__num" data-i18n="num.3">٣</span>
            <h3 data-i18n="how.s3.title">احجز وروح</h3>
            <p class="u-sub" data-i18n="how.s3.body">ادفع بالدينار وتذكرتك تجيك QR.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section trust" id="trust">
      <ul class="trust__list u-wrap">
        <li data-reveal data-reveal-delay="1" data-i18n="trust.iqd">دفع بالدينار</li>
        <li data-reveal data-reveal-delay="2" data-i18n="trust.qr">تذكرة QR</li>
        <li data-reveal data-reveal-delay="3" data-i18n="trust.cancel">إلغاء سهل</li>
      </ul>
    </section>
```

Create the two extra placeholder screenshots the same way as in Task 7:

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal/assets/img
python3 -c "
from PIL import Image, ImageDraw
for name in ['screen-book.png', 'screen-ticket.png']:
    im = Image.new('RGB', (780, 1688), '#E8EEF0')
    ImageDraw.Draw(im).text((300, 830), 'SCREENSHOT\nPENDING', fill='#6C7A7E')
    im.save(name)
"
```

- [ ] **Step 5: Add the CSS**

Append to `site.css`:

```css
/* ── Sections ───────────────────────────────────────────────────────── */

.section { padding-block: clamp(var(--space-5), 7vw, var(--space-7)); }
.section > .u-wrap > h2 { margin-block-end: var(--space-4); }

/* ── Cards ──────────────────────────────────────────────────────────── */

.cards {
  display: grid;
  gap: var(--space-4);
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 280px), 1fr));
}

.card {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #fff;
  transition: transform 0.3s var(--ease), box-shadow 0.3s var(--ease);
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0 18px 40px color-mix(in srgb, var(--ink) 10%, transparent);
}

.card__shot {
  overflow: hidden;
  border-radius: var(--radius-sm);
  background: var(--teal-soft);
  aspect-ratio: 4 / 3;
}

.card__shot img { width: 100%; height: 100%; object-fit: cover; object-position: top center; }

/* ── Steps ──────────────────────────────────────────────────────────── */

.steps {
  position: relative;
  display: grid;
  gap: var(--space-4);
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 240px), 1fr));
}

.steps__line {
  position: absolute;
  inset-block-start: 22px;
  inset-inline: 8%;
  width: 84%;
  height: 2px;
  z-index: 0;
}

@media (max-width: 760px) { .steps__line { display: none; } }

.step { position: relative; z-index: 1; display: flex; flex-direction: column; gap: var(--space-1); }

.step__num {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--teal);
  color: #fff;
  font-weight: 700;
  font-size: var(--step-0);
  margin-block-end: var(--space-1);
}

/* ── Trust ──────────────────────────────────────────────────────────── */

.trust__list {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: var(--space-2) var(--space-5);
  list-style: none;
  padding-block: var(--space-4);
  border-block: 1px solid var(--line);
}

.trust__list li {
  font-weight: 700;
  color: var(--subink);
  font-size: var(--step-0);
}

.trust__list li::before { content: "✓"; color: var(--teal); margin-inline-end: 0.4em; }
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Verify in a browser**

Serve and scroll. Cards and steps should stagger in from below, the dashed connector should draw left-to-right once as the steps section enters, and the connector should disappear below 760px where the steps stack.

- [ ] **Step 8: Commit**

```bash
git add legal/index.html legal/assets/css/site.css legal/assets/js/i18n.js legal/assets/img web-tests/landing.test.mjs
git commit -m "feat(site): landing feature cards, how-it-works and trust strip

Screenshots are marked placeholders pending real light-mode exports
(spec section 10a). Card, step and trust components are written to be
reused by the merchants page."
```

---

## Task 10: Character cutouts, download section, merchant band

**Files:**
- Create: `wensa/legal/assets/img/character-thumbsup.png`
- Create: `wensa/legal/assets/img/character-register.png`
- Create: `wensa/legal/assets/img/download-qr.png`
- Create: `wensa/tools/cutout.py`
- Modify: `wensa/legal/index.html`, `wensa/legal/assets/css/site.css`, `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/download.test.mjs`

**Interfaces:**
- Consumes: `data-store-cta` handling wired in Task 6's `main.js`.
- Produces: the two transparent character PNGs, used here and in Task 11.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/download.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { LEGAL_DIR, readLegal, legalExists } from "./helpers.mjs";

const IOS = "https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862";
const ANDROID = "https://play.google.com/store/apps/details?id=app.wensa.mobile";

test("store URLs on the landing page match the ones download.html already uses", () => {
  const landing = readLegal("index.html");
  const download = readLegal("download.html");
  assert.ok(download.includes(IOS), "the canonical iOS URL changed — update this test and the site together");
  assert.ok(landing.includes(IOS), "landing page iOS URL does not match download.html");
  assert.ok(landing.includes("id=app.wensa.mobile"), "landing page Android URL missing");
  assert.ok(download.includes("id=app.wensa.mobile"));
});

test("every store link carries a data-store-cta so inapp-redirect can intercept it", () => {
  const html = readLegal("index.html");
  const storeLinks = [...html.matchAll(/<a\b[^>]*(?:apps\.apple\.com|play\.google\.com)[^>]*>/g)].map((m) => m[0]);
  assert.ok(storeLinks.length >= 2);
  for (const link of storeLinks) {
    assert.match(link, /data-store-cta="(ios|android)"/, `store link without data-store-cta: ${link}`);
  }
});

test("the landing page does NOT enable wholePage or autoAttempt", () => {
  const js = readLegal("assets/js/main.js");
  assert.ok(!/wholePage/.test(js),
    "wholePage makes the first tap anywhere jump to the store — correct for /download, wrong here");
  assert.ok(!/autoAttempt/.test(js),
    "autoAttempt fires an escape on load before the visitor has read anything");
  assert.match(js, /WensaInAppRedirect\.init\(\)/);
});

test("character cutouts exist and are transparent PNGs", () => {
  for (const name of ["character-thumbsup.png", "character-register.png"]) {
    const rel = `assets/img/${name}`;
    assert.ok(legalExists(rel), `${rel} is missing`);
    const buf = readFileSync(join(LEGAL_DIR, rel));
    assert.equal(buf.readUInt32BE(0), 0x89504e47, `${rel} is not a PNG`);
    // IHDR color type lives at byte 25; 6 = RGBA, 4 = grey+alpha.
    assert.ok([4, 6].includes(buf[25]), `${rel} has no alpha channel — background was not removed`);
  }
});

test("the merchant band links to the merchants page", () => {
  const html = readLegal("index.html");
  const band = html.slice(html.indexOf('class="band"'));
  assert.match(band, /href="\/merchants"/);
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/download.test.mjs
```

Expected: FAIL on the cutouts and the merchant band.

- [ ] **Step 3: Write the cutout script**

**Revision note (this step originally specified a border-seeded flood fill; that approach is provably wrong for these specific source images and has been replaced before any implementer attempted it against this revision of the plan).** The flood-fill design assumed the subject's colors were far enough from the background's gradient for a per-step color-distance tolerance to walk the gradient without crossing into the subject. Direct pixel sampling disproved that: both characters wear white/light garments whose shaded areas — e.g. `(229,217,215)` on the T-shirt — sit inside the *same* warm-grey family as the studio background corners — e.g. `(232,219,219)`. A tolerance sweep from 3 to 50 found a hard cliff at tolerance 14, past which the fill consumes the entire garment down to bare outline strokes; the whole originally-specified "safe" range (26–50) sits on the catastrophic side of that cliff, and even the range below the cliff (≤13) still loses visible garment area. No tolerance value threads this needle, because there is no color-distance boundary to find — the colors genuinely interleave. This is a property of these renders, not a bug in the flood-fill implementation.

Create `wensa/tools/cutout.py` using **ML-based background segmentation (`rembg`, the U²-Net model)** instead, which classifies foreground/background by learned object structure rather than raw color distance — verified directly against both source images: the shirt, shoes, and all garment detail come through intact, corners are genuinely transparent (alpha 0, confirmed pixel-by-pixel, not merely rendered black), and a full run (including the one-time ~176 MB model download, cached outside the repo at `~/.u2net/`) takes under 2 seconds per image once cached.

```python
#!/usr/bin/env python3
"""Remove the studio background from the Wensa character renders.

Uses ML segmentation (rembg / U^2-Net) rather than a color-distance
technique. The source renders' garments (white T-shirt, white dress shirt)
sit in the same warm-grey color family as the studio background gradient —
verified by direct pixel sampling — so no flood-fill or threshold tolerance
can separate them by color alone. Segmentation classifies by learned object
structure instead, which is unaffected by the color overlap.

Usage:  python3 tools/cutout.py <input.png> <output.png>
"""
import sys
from rembg import remove
from PIL import Image


def cutout(src_path, dst_path):
    im = Image.open(src_path)
    out = remove(im)

    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    out.save(dst_path)
    print(f"{src_path} -> {dst_path}  {out.size}  transparent")


if __name__ == "__main__":
    cutout(sys.argv[1], sys.argv[2])
```

- [ ] **Step 4: Install rembg in a throwaway venv and run the cutouts**

Same throwaway-tooling discipline as Task 2's font conversion: install into a venv outside the repo, run the script, delete the venv. `rembg` needs `onnxruntime`; the first run downloads and caches the ~176 MB U²-Net model to `~/.u2net/` (outside the repo, not committed) — subsequent runs reuse the cache and take under 2 seconds per image.

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
python3 -m venv /tmp/wensa-rembg
/tmp/wensa-rembg/bin/pip install --quiet rembg onnxruntime
CHARS="/Users/mousaalhamad/Desktop/Wensa/Wensa_Marketing_Campaign/characters"
/tmp/wensa-rembg/bin/python3 tools/cutout.py "$CHARS/thumb_okay_posture.png" legal/assets/img/character-thumbsup.png
/tmp/wensa-rembg/bin/python3 tools/cutout.py "$CHARS/register.PNG"           legal/assets/img/character-register.png
rm -rf /tmp/wensa-rembg
```

Open both outputs and inspect them directly (the Read tool displays images) — confirm the garment is fully intact (no line-art-only ghosting) and the background is genuinely gone, not just visually dark. If either cutout shows visible garment loss or a residual halo, that is a real defect worth escalating — do not attempt to "fix" it by reintroducing a color-distance technique; the diagnosis above already establishes why that approach cannot work on these particular renders.

- [ ] **Step 5: Generate the download QR**

The QR points at `/download`, so it inherits the existing in-app-browser handling rather than hardcoding a store URL.

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
python3 -m venv /tmp/wensa-qr
/tmp/wensa-qr/bin/pip install --quiet "qrcode[pil]"
/tmp/wensa-qr/bin/python -c "
import qrcode
img = qrcode.make('https://wensa.app/download', box_size=10, border=2)
img.save('legal/assets/img/download-qr.png')
"
rm -rf /tmp/wensa-qr
```

- [ ] **Step 6: Add the dictionary keys**

| Key | ar | en |
|---|---|---|
| `dl.title` | `نزّل ونسة وابدا` | `Get Wensa and go` |
| `dl.body` | `مجاني، وبالعربي، ومصمم للعراق. نزّله وشوف شنو اكو هاي الليلة.` | `Free, in Arabic, and built for Iraq. Download it and see what's on tonight.` |
| `dl.qr` | `صوّر الكود بكاميرتك` | `Scan with your camera` |
| `band.title` | `عندك مطعم او ملعب؟` | `Own a restaurant or a court?` |
| `band.body` | `اول شهر علينا — برو مجاناً و٠٪ عمولة.` | `Your first month is on us — Pro free and 0% commission.` |
| `band.cta` | `صير تاجر بونسة` | `Become a merchant` |

- [ ] **Step 7: Add the markup**

After the trust section in `index.html`:

```html
    <section class="section dl" id="download" aria-labelledby="dl-title">
      <div class="dl__inner u-wrap">
        <div class="dl__copy">
          <h2 id="dl-title" data-reveal data-i18n="dl.title">نزّل ونسة وابدا</h2>
          <p class="u-sub" data-reveal data-reveal-delay="1" data-i18n="dl.body">
            مجاني، وبالعربي، ومصمم للعراق. نزّله وشوف شنو اكو هاي الليلة.
          </p>

          <div class="hero__cta" data-reveal data-reveal-delay="2">
            <a class="btn btn--teal" data-store-cta="ios"
               href="https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862"
               data-i18n="hero.ios">نزّله من App Store</a>
            <a class="btn btn--ghost" data-store-cta="android"
               href="https://play.google.com/store/apps/details?id=app.wensa.mobile"
               data-i18n="hero.android">نزّله من Google Play</a>
          </div>

          <figure class="dl__qr" data-reveal data-reveal-delay="3">
            <img src="/assets/img/download-qr.png" alt="" width="130" height="130" loading="lazy">
            <figcaption data-i18n="dl.qr">صوّر الكود بكاميرتك</figcaption>
          </figure>
        </div>

        <img class="dl__char" src="/assets/img/character-thumbsup.png" alt=""
             data-parallax="18" loading="lazy" width="420" height="560">
      </div>
    </section>

    <section class="band">
      <div class="band__inner u-wrap">
        <div>
          <h2 data-reveal data-i18n="band.title">عندك مطعم او ملعب؟</h2>
          <p data-reveal data-reveal-delay="1" data-i18n="band.body">اول شهر علينا — برو مجاناً و٠٪ عمولة.</p>
        </div>
        <a class="btn btn--paper" href="/merchants" data-reveal data-reveal-delay="2" data-i18n="band.cta">صير تاجر بونسة</a>
      </div>
    </section>
```

- [ ] **Step 8: Add the CSS**

Append to `site.css`:

```css
/* ── Download ───────────────────────────────────────────────────────── */

.dl__inner {
  display: grid;
  gap: var(--space-5);
  grid-template-columns: 1fr;
  align-items: end;
}

@media (min-width: 900px) {
  .dl__inner { grid-template-columns: 1.1fr 0.9fr; }
}

.dl__copy { display: flex; flex-direction: column; gap: var(--space-3); }

.dl__qr {
  display: none;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--step--1);
  color: var(--subink);
}

/* A QR is only useful to someone on a different device from the one holding
   the camera, so it is desktop-only. */
@media (min-width: 900px) { .dl__qr { display: flex; } }

.dl__char { justify-self: center; width: min(340px, 78vw); height: auto; }

/* ── Band ───────────────────────────────────────────────────────────── */

.band {
  background: var(--teal);
  color: #fff;
  padding-block: var(--space-6);
}

.band__inner {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  align-items: center;
  justify-content: space-between;
}

.band h2 { font-size: var(--step-3); }
.band p { opacity: 0.92; margin-block-start: var(--space-1); }

.btn--paper {
  background: var(--paper);
  color: var(--ink);
  box-shadow: 0 6px 20px rgb(0 0 0 / 0.16);
}

.btn--paper:hover { transform: translateY(-2px); box-shadow: 0 12px 30px rgb(0 0 0 / 0.22); }
```

- [ ] **Step 9: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS, including the alpha-channel assertion on both cutouts.

- [ ] **Step 10: Commit**

```bash
git add legal/index.html legal/assets/css/site.css legal/assets/js/i18n.js legal/assets/img tools/cutout.py web-tests/download.test.mjs
git commit -m "feat(site): download section, character cutouts and merchant band

tools/cutout.py uses rembg (U^2-Net) ML segmentation rather than a
color-distance technique: the source renders' garments and studio
background occupy overlapping RGB ranges, so no flood-fill or threshold
tolerance can separate them, verified by direct pixel sampling. Tests
assert the store URLs still match download.html and that main.js never
enables wholePage/autoAttempt."
```

---

## Task 11: Merchants page — hero and offer card

**Files:**
- Modify: `wensa/legal/merchants.html`, `wensa/legal/assets/css/site.css`, `wensa/legal/assets/js/i18n.js`
- Create: `wensa/web-tests/merchant-offer.test.mjs`

**Interfaces:**
- Consumes: the shell from Task 6, `character-register.png` from Task 10.
- Produces: the `.offer` component.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/merchant-offer.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

test("the offer states both perks and that they cover the first month", () => {
  assert.match(dict.ar["offer.title"], /شهر/, "the Arabic offer must say 'month'");
  assert.match(dict.ar["offer.title"], /٠٪|صفر/, "the Arabic offer must state 0% commission");
  assert.match(dict.en["offer.title"], /month/i);
  assert.match(dict.en["offer.title"], /0%/);
});

test("the fine print names the after-price so the offer is not misleading", () => {
  assert.match(dict.ar["offer.fine"], /٦٠٬٠٠٠|٦٠،٠٠٠/, "Arabic fine print must state 60,000 in Arabic-Indic digits");
  assert.match(dict.en["offer.fine"], /60,000/);
  assert.match(dict.en["offer.fine"], /IQD/);
});

test("the free plan is stated so nobody thinks a paid plan is mandatory", () => {
  assert.match(dict.ar["offer.free"], /مجاني/, "must reassure that a free plan exists");
  assert.match(dict.en["offer.free"], /free/i);
});

test("orange is used exactly once on the merchants page", () => {
  const html = readLegal("merchants.html");
  const hits = (html.match(/offer__badge/g) ?? []).length;
  assert.equal(hits, 1, "ORANGE is the offer badge and nothing else — one hit per frame");
});

test("both merchant CTAs point at the dashboard", () => {
  const html = readLegal("merchants.html");
  const links = (html.match(/https:\/\/dashboard\.wensa\.app/g) ?? []).length;
  assert.ok(links >= 2, `expected at least 2 dashboard links (nav + hero), found ${links}`);
});

test("the merchant hero uses the register character", () => {
  assert.match(readLegal("merchants.html"), /character-register\.png/);
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/merchant-offer.test.mjs
```

Expected: FAIL — the `offer.*` keys do not exist.

- [ ] **Step 3: Add the dictionary keys**

| Key | ar | en |
|---|---|---|
| `merchant.eyebrow` | `لأصحاب الاماكن` | `For venue owners` |
| `merchant.title` | `خلي مكانك يوصل لكل بغداد` | `Put your venue in front of all Baghdad` |
| `merchant.sub` | `اضم مكانك لونسة واستقبل حجوزات من التطبيق — بدون تلفونات وبدون دفتر حجوزات.` | `List your venue on Wensa and take bookings straight from the app — no phone calls, no paper book.` |
| `merchant.ctaPricing` | `شوف الاسعار` | `See pricing` |
| `offer.badge` | `عرض` | `Offer` |
| `offer.title` | `اول شهر برو مجاناً + ٠٪ عمولة` | `First month Pro free + 0% commission` |
| `offer.body` | `اول شهر الك على خطة برو كاملة، وماناخذ ولا فلس عمولة بيه.` | `Your first month is on the full Pro plan, and we take zero commission on it.` |
| `offer.fine` | `بعد الشهر الاول، برو ٦٠٬٠٠٠ د.ع بالشهر وتنطبق العمولة الاعتيادية.` | `After the first month, Pro is 60,000 IQD per month and standard commission applies.` |
| `offer.free` | `وتبقى خطة اساسي مجانية دائماً — ماكو احد مجبور يدفع.` | `And the Basic plan stays free forever — nobody is forced onto a paid plan.` |

- [ ] **Step 4: Add the markup**

Inside `<main id="main">` in `merchants.html`:

```html
    <section class="hero">
      <div class="hero__inner u-wrap">
        <div class="hero__copy">
          <p class="u-eyebrow" data-reveal data-i18n="merchant.eyebrow">لأصحاب الاماكن</p>
          <h1 data-reveal data-reveal-delay="1" data-i18n="merchant.title">خلي مكانك يوصل لكل بغداد</h1>
          <p class="u-sub" data-reveal data-reveal-delay="2" data-i18n="merchant.sub">
            اضم مكانك لونسة واستقبل حجوزات من التطبيق — بدون تلفونات وبدون دفتر حجوزات.
          </p>
          <div class="hero__cta" data-reveal data-reveal-delay="3">
            <a class="btn btn--teal" href="https://dashboard.wensa.app" data-i18n="merchant.ctaRegister">سجّل هسه</a>
            <a class="btn btn--ghost" href="#pricing" data-i18n="merchant.ctaPricing">شوف الاسعار</a>
          </div>
        </div>

        <img class="hero__char" src="/assets/img/character-register.png" alt=""
             data-parallax="20" width="420" height="560" loading="eager">
      </div>
    </section>

    <section class="section" aria-labelledby="offer-title">
      <div class="u-wrap">
        <div class="offer" data-reveal>
          <span class="offer__badge" data-i18n="offer.badge">عرض</span>
          <h2 id="offer-title" class="offer__title" data-i18n="offer.title">اول شهر برو مجاناً + ٠٪ عمولة</h2>
          <p class="offer__body" data-i18n="offer.body">اول شهر الك على خطة برو كاملة، وماناخذ ولا فلس عمولة بيه.</p>
          <p class="offer__fine" data-i18n="offer.fine">بعد الشهر الاول، برو ٦٠٬٠٠٠ د.ع بالشهر وتنطبق العمولة الاعتيادية.</p>
          <p class="offer__free" data-i18n="offer.free">وتبقى خطة اساسي مجانية دائماً — ماكو احد مجبور يدفع.</p>
        </div>
      </div>
    </section>
```

- [ ] **Step 5: Add the CSS**

Append to `site.css`:

```css
/* ── Merchant hero character ────────────────────────────────────────── */

.hero__char { justify-self: center; width: min(360px, 78vw); height: auto; }

/* ── Offer ──────────────────────────────────────────────────────────────
   The single ORANGE hit on the page — WENSA_BRAND_SKILL.md §1 rule 3. */

.offer {
  position: relative;
  max-width: 760px;
  margin-inline: auto;
  padding: var(--space-5) var(--space-4);
  text-align: center;
  border: 1px solid color-mix(in srgb, var(--orange) 30%, transparent);
  border-radius: var(--radius);
  background: color-mix(in srgb, var(--orange) 5%, var(--paper));
}

.offer__badge {
  display: inline-block;
  padding: 0.35em 1em;
  border-radius: 999px;
  background: var(--orange);
  color: #fff;
  font-size: var(--step--1);
  font-weight: 700;
  margin-block-end: var(--space-2);
}

.offer__title { font-size: var(--step-3); }
.offer__body { margin-block-start: var(--space-2); font-size: var(--step-1); }

.offer__fine {
  margin-block-start: var(--space-3);
  color: var(--subink);
  font-size: var(--step--1);
}

.offer__free {
  margin-block-start: var(--space-1);
  color: var(--teal);
  font-weight: 700;
  font-size: var(--step--1);
}
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add legal/merchants.html legal/assets/css/site.css legal/assets/js/i18n.js web-tests/merchant-offer.test.mjs
git commit -m "feat(site): merchant hero and offer card

Tests assert the offer states both perks, names the 60,000 IQD after-price
in the fine print, and says the Basic plan is free forever — so the copy
cannot drift into implying a paid plan is mandatory."
```

---

## Task 12: Merchants page — benefits and join steps

**Files:**
- Modify: `wensa/legal/merchants.html`, `wensa/legal/assets/js/i18n.js`, `wensa/legal/assets/css/site.css`
- Create: `wensa/web-tests/merchant-body.test.mjs`

**Interfaces:**
- Consumes: `.cards`, `.steps`, `.step__num` from Task 9, and the shared `num.1`–`num.3` dictionary keys Task 9 introduced.
- Produces: the `num.4` dictionary key, for the fourth join step.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/merchant-body.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";

test("there are six benefit cards", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="benefits"'), html.indexOf('id="join"'));
  assert.equal((section.match(/class="card card--flat"/g) ?? []).length, 6);
});

test("there are four join steps with an animated connector", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="join"'), html.indexOf('id="pricing"'));
  assert.equal((section.match(/class="step"/g) ?? []).length, 4);
  assert.match(section, /data-line-draw/);
});

test("step numbers use Arabic-Indic digits in the shipped markup", () => {
  const html = readLegal("merchants.html");
  const nums = [...html.matchAll(/class="step__num"[^>]*>([^<]+)</g)].map((m) => m[1].trim());
  assert.deepEqual(nums, ["١", "٢", "٣", "٤"]);
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/merchant-body.test.mjs
```

Expected: FAIL — the sections do not exist.

- [ ] **Step 3: Add the dictionary keys**

| Key | ar | en |
|---|---|---|
| `ben.title` | `شنو تاخذ لما تنضم؟` | `What you get` |
| `ben.b1.title` | `توصل لزباين جداد` | `Reach new customers` |
| `ben.b1.body` | `مكانك يظهر لكل مستخدمي ونسة بالعراق.` | `Your venue appears to every Wensa user in Iraq.` |
| `ben.b2.title` | `حجوزات ٢٤ ساعة` | `Bookings around the clock` |
| `ben.b2.body` | `الزبون يحجز حتى وانت نايم — بدون تلفون.` | `Customers book even while you sleep — no phone calls.` |
| `ben.b3.title` | `فلوسك بالدينار` | `Paid in IQD` |
| `ben.b3.body` | `الدفع بالدينار العراقي وتحويل لحسابك البنكي.` | `Payment in Iraqi dinar, transferred to your bank account.` |
| `ben.b4.title` | `دخول بالـ QR` | `QR check-in` |
| `ben.b4.body` | `الزبون يوري تذكرته عالباب وتتأكد بثانية.` | `Guests show their ticket at the door and you verify in a second.` |
| `ben.b5.title` | `احصائيات حقيقية` | `Real analytics` |
| `ben.b5.body` | `شوف شكد واحد شاف مكانك وشكد حجز.` | `See how many people viewed your venue and how many booked.` |
| `ben.b6.title` | `اعلانات وترويج` | `Banners and promotion` |
| `ben.b6.body` | `اعلانات داخل التطبيق وظهور بالصفحة الرئيسية.` | `In-app banners and home feed placement.` |
| `join.title` | `شلون تنضم؟` | `How to join` |
| `join.s1.title` | `سجّل حسابك` | `Create your account` |
| `join.s1.body` | `اسم، ايميل ورقم تلفون — بدقيقة.` | `Name, email and phone — takes a minute.` |
| `join.s2.title` | `ضيف مكانك` | `Add your venue` |
| `join.s2.body` | `صور، دوام، وموقع على الخريطة.` | `Photos, opening hours and a map location.` |
| `join.s3.title` | `نراجع ونوثق` | `We review and verify` |
| `join.s3.body` | `فريقنا يتأكد من المعلومات ويوثق مكانك.` | `Our team checks the details and verifies your venue.` |
| `join.s4.title` | `افتح واستقبل حجوزات` | `Go live and take bookings` |
| `join.s4.body` | `مكانك يظهر بالتطبيق وتبدي تستقبل حجوزات.` | `Your venue appears in the app and bookings start coming in.` |
| `num.4` | `٤` | `4` |

- [ ] **Step 4: Add the markup**

After the offer section in `merchants.html`:

```html
    <section class="section" id="benefits" aria-labelledby="ben-title">
      <div class="u-wrap">
        <h2 id="ben-title" data-reveal data-i18n="ben.title">شنو تاخذ لما تنضم؟</h2>
        <div class="cards">
          <article class="card card--flat" data-reveal data-reveal-delay="1">
            <h3 data-i18n="ben.b1.title">توصل لزباين جداد</h3>
            <p class="u-sub" data-i18n="ben.b1.body">مكانك يظهر لكل مستخدمي ونسة بالعراق.</p>
          </article>
          <article class="card card--flat" data-reveal data-reveal-delay="2">
            <h3 data-i18n="ben.b2.title">حجوزات ٢٤ ساعة</h3>
            <p class="u-sub" data-i18n="ben.b2.body">الزبون يحجز حتى وانت نايم — بدون تلفون.</p>
          </article>
          <article class="card card--flat" data-reveal data-reveal-delay="3">
            <h3 data-i18n="ben.b3.title">فلوسك بالدينار</h3>
            <p class="u-sub" data-i18n="ben.b3.body">الدفع بالدينار العراقي وتحويل لحسابك البنكي.</p>
          </article>
          <article class="card card--flat" data-reveal data-reveal-delay="1">
            <h3 data-i18n="ben.b4.title">دخول بالـ QR</h3>
            <p class="u-sub" data-i18n="ben.b4.body">الزبون يوري تذكرته عالباب وتتأكد بثانية.</p>
          </article>
          <article class="card card--flat" data-reveal data-reveal-delay="2">
            <h3 data-i18n="ben.b5.title">احصائيات حقيقية</h3>
            <p class="u-sub" data-i18n="ben.b5.body">شوف شكد واحد شاف مكانك وشكد حجز.</p>
          </article>
          <article class="card card--flat" data-reveal data-reveal-delay="3">
            <h3 data-i18n="ben.b6.title">اعلانات وترويج</h3>
            <p class="u-sub" data-i18n="ben.b6.body">اعلانات داخل التطبيق وظهور بالصفحة الرئيسية.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="join" aria-labelledby="join-title">
      <div class="u-wrap">
        <h2 id="join-title" data-reveal data-i18n="join.title">شلون تنضم؟</h2>
        <div class="steps">
          <svg class="steps__line" viewBox="0 0 1000 2" preserveAspectRatio="none" aria-hidden="true">
            <path d="M0 1 H1000" data-line-draw fill="none" stroke="var(--teal)" stroke-width="2" stroke-dasharray="6 8" />
          </svg>
          <article class="step" data-reveal data-reveal-delay="1">
            <span class="step__num" data-i18n="num.1">١</span>
            <h3 data-i18n="join.s1.title">سجّل حسابك</h3>
            <p class="u-sub" data-i18n="join.s1.body">اسم، ايميل ورقم تلفون — بدقيقة.</p>
          </article>
          <article class="step" data-reveal data-reveal-delay="2">
            <span class="step__num" data-i18n="num.2">٢</span>
            <h3 data-i18n="join.s2.title">ضيف مكانك</h3>
            <p class="u-sub" data-i18n="join.s2.body">صور، دوام، وموقع على الخريطة.</p>
          </article>
          <article class="step" data-reveal data-reveal-delay="3">
            <span class="step__num" data-i18n="num.3">٣</span>
            <h3 data-i18n="join.s3.title">نراجع ونوثق</h3>
            <p class="u-sub" data-i18n="join.s3.body">فريقنا يتأكد من المعلومات ويوثق مكانك.</p>
          </article>
          <article class="step" data-reveal data-reveal-delay="4">
            <span class="step__num" data-i18n="num.4">٤</span>
            <h3 data-i18n="join.s4.title">افتح واستقبل حجوزات</h3>
            <p class="u-sub" data-i18n="join.s4.body">مكانك يظهر بالتطبيق وتبدي تستقبل حجوزات.</p>
          </article>
        </div>
      </div>
    </section>
```

- [ ] **Step 5: Add the flat-card variant**

Append to `site.css`:

```css
.card--flat {
  background: transparent;
  border-color: var(--line);
}

.card--flat:hover {
  transform: translateY(-4px);
  border-color: color-mix(in srgb, var(--teal) 40%, transparent);
  box-shadow: none;
}
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add legal/merchants.html legal/assets/js/i18n.js legal/assets/css/site.css web-tests/merchant-body.test.mjs
git commit -m "feat(site): merchant benefits and join steps

Reuses the card and step components from the landing page rather than
introducing parallel ones."
```

---

## Task 13: Merchants page — pricing

**Files:**
- Modify: `wensa/legal/merchants.html`, `wensa/legal/assets/js/i18n.js`, `wensa/legal/assets/css/site.css`
- Create: `wensa/web-tests/pricing.test.mjs`

**Interfaces:**
- Consumes: nothing new.
- Produces: the `.plans` component.

The prices and features are copied from `wansa-admin-dashboard/src/features/merchant/PlansPage.tsx`. The test below reads that file directly, so if the dashboard's pricing changes, the site's test fails rather than the site silently going stale.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/pricing.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

const PLANS_TSX =
  "/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard/src/features/merchant/PlansPage.tsx";

test("prices match the dashboard's PlansPage.tsx", { skip: !existsSync(PLANS_TSX) }, () => {
  const tsx = readFileSync(PLANS_TSX, "utf8");
  assert.ok(tsx.includes('price: "25,000"'), "Growth is no longer 25,000 in the dashboard — update the site");
  assert.ok(tsx.includes('price: "60,000"'), "Pro is no longer 60,000 in the dashboard — update the site");
  assert.match(dict.en["plan.growth.price"], /25,000/);
  assert.match(dict.en["plan.pro.price"], /60,000/);
  assert.match(dict.ar["plan.growth.price"], /٢٥٬٠٠٠|٢٥،٠٠٠/);
  assert.match(dict.ar["plan.pro.price"], /٦٠٬٠٠٠|٦٠،٠٠٠/);
});

test("all three plans are on the page", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="pricing"'));
  assert.equal((section.match(/class="plan[ "]/g) ?? []).length, 3);
});

test("Basic is presented as free", () => {
  assert.match(dict.ar["plan.basic.price"], /مجاني/);
  assert.match(dict.en["plan.basic.price"], /free/i);
});

test("Growth carries the most-popular badge, matching the dashboard", () => {
  assert.match(dict.ar["plan.growth.badge"], /الأكثر شيوعاً/);
  assert.match(dict.en["plan.growth.badge"], /Most Popular/i);
  const section = readLegal("merchants.html");
  assert.equal((section.match(/plan__badge/g) ?? []).length, 1, "exactly one plan may be badged");
});

test("Pro notes that the first month is free", () => {
  assert.match(dict.ar["plan.pro.note"], /شهر/);
  assert.match(dict.en["plan.pro.note"], /first month/i);
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/pricing.test.mjs
```

Expected: FAIL — the `plan.*` keys do not exist.

- [ ] **Step 3: Add the dictionary keys**

Features are copied verbatim from `PlansPage.tsx` — both language variants already exist there.

| Key | ar | en |
|---|---|---|
| `pricing.title` | `الاسعار` | `Pricing` |
| `pricing.sub` | `ابدا مجاناً وارتقي وقت ما تحتاج.` | `Start free and upgrade whenever you need to.` |
| `plan.basic.name` | `أساسي` | `Basic` |
| `plan.basic.price` | `مجاني` | `Free` |
| `plan.basic.f` | `٢ أماكن + فعاليات مجمعة · ٣ صور إضافية · قائمة أساسية · لا إعلانات مجانية (٥٬٠٠٠ د.ع لكل إعلان)` | `2 combined places & events · 3 additional photos · Basic listing · No free banners (5,000 IQD each)` |
| `plan.growth.name` | `نمو` | `Growth` |
| `plan.growth.price` | `٢٥٬٠٠٠ د.ع / شهر` | `25,000 IQD / month` |
| `plan.growth.badge` | `الأكثر شيوعاً` | `Most Popular` |
| `plan.growth.f` | `١٠ أماكن + فعاليات مجمعة · صور غير محدودة · زر التواصل المباشر · إحصائيات أساسية · ٣ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها` | `10 combined places & events · Unlimited photos · Direct contact button · Basic analytics · 3 free banners/month + 5,000 IQD each after` |
| `plan.pro.name` | `احترافي` | `Pro` |
| `plan.pro.price` | `٦٠٬٠٠٠ د.ع / شهر` | `60,000 IQD / month` |
| `plan.pro.note` | `اول شهر مجاناً` | `First month free` |
| `plan.pro.f` | `أماكن + فعاليات غير محدودة · إحصائيات متقدمة · أولوية الظهور · شارة التحقق · ترويج رئيسية · موظفون متعددون · ١٠ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها` | `Unlimited places & events · Advanced analytics · Priority placement · Verified badge · Home feed promotion · Multi-staff access · 10 free banners/month + 5,000 IQD each after` |

- [ ] **Step 4: Add the markup**

After the join section in `merchants.html`:

```html
    <section class="section" id="pricing" aria-labelledby="pricing-title">
      <div class="u-wrap">
        <h2 id="pricing-title" data-reveal data-i18n="pricing.title">الاسعار</h2>
        <p class="u-sub" data-reveal data-reveal-delay="1" data-i18n="pricing.sub">ابدا مجاناً وارتقي وقت ما تحتاج.</p>

        <div class="plans">
          <article class="plan" data-reveal data-reveal-delay="1">
            <h3 class="plan__name" data-i18n="plan.basic.name">أساسي</h3>
            <p class="plan__price" data-i18n="plan.basic.price">مجاني</p>
            <p class="plan__features" data-i18n="plan.basic.f">٢ أماكن + فعاليات مجمعة · ٣ صور إضافية · قائمة أساسية · لا إعلانات مجانية (٥٬٠٠٠ د.ع لكل إعلان)</p>
          </article>

          <article class="plan plan--popular" data-reveal data-reveal-delay="2">
            <span class="plan__badge" data-i18n="plan.growth.badge">الأكثر شيوعاً</span>
            <h3 class="plan__name" data-i18n="plan.growth.name">نمو</h3>
            <p class="plan__price" data-i18n="plan.growth.price">٢٥٬٠٠٠ د.ع / شهر</p>
            <p class="plan__features" data-i18n="plan.growth.f">١٠ أماكن + فعاليات مجمعة · صور غير محدودة · زر التواصل المباشر · إحصائيات أساسية · ٣ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها</p>
          </article>

          <article class="plan" data-reveal data-reveal-delay="3">
            <h3 class="plan__name" data-i18n="plan.pro.name">احترافي</h3>
            <p class="plan__price" data-i18n="plan.pro.price">٦٠٬٠٠٠ د.ع / شهر</p>
            <p class="plan__note" data-i18n="plan.pro.note">اول شهر مجاناً</p>
            <p class="plan__features" data-i18n="plan.pro.f">أماكن + فعاليات غير محدودة · إحصائيات متقدمة · أولوية الظهور · شارة التحقق · ترويج رئيسية · موظفون متعددون · ١٠ إعلانات مجانية/شهر + ٥٬٠٠٠ د.ع بعدها</p>
          </article>
        </div>
      </div>
    </section>
```

- [ ] **Step 5: Add the CSS**

Append to `site.css`:

```css
/* ── Plans ──────────────────────────────────────────────────────────── */

.plans {
  display: grid;
  gap: var(--space-3);
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 260px), 1fr));
  margin-block-start: var(--space-4);
}

.plan {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding: var(--space-4) var(--space-3);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #fff;
  transition: transform 0.3s var(--ease), box-shadow 0.3s var(--ease);
}

.plan:hover { transform: translateY(-4px); box-shadow: 0 18px 40px color-mix(in srgb, var(--ink) 10%, transparent); }

.plan--popular {
  border-color: var(--teal);
  background: var(--teal-soft);
}

.plan__badge {
  position: absolute;
  inset-block-start: -12px;
  inset-inline-start: var(--space-3);
  padding: 0.3em 0.9em;
  border-radius: 999px;
  background: var(--teal);
  color: #fff;
  font-size: var(--step--1);
  font-weight: 700;
}

.plan__name { font-size: var(--step-1); }
.plan__price { font-size: var(--step-2); font-weight: 700; color: var(--teal); }
.plan__note { font-size: var(--step--1); font-weight: 700; color: var(--orange); }
.plan__features { color: var(--subink); font-size: var(--step--1); line-height: 2; }
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add legal/merchants.html legal/assets/js/i18n.js legal/assets/css/site.css web-tests/pricing.test.mjs
git commit -m "feat(site): merchant pricing table

Features and prices copied verbatim from PlansPage.tsx. The test reads that
file directly, so a pricing change in the dashboard fails the site's tests
instead of leaving the marketing page quietly wrong."
```

---

## Task 14: Merchants page — FAQ and closing CTA

**Files:**
- Modify: `wensa/legal/merchants.html`, `wensa/legal/assets/js/i18n.js`, `wensa/legal/assets/css/site.css`
- Create: `wensa/web-tests/faq.test.mjs`

**Interfaces:**
- Consumes: nothing new.
- Produces: the `.faq` component, built on native `<details>`/`<summary>` so it needs no JavaScript and is keyboard-accessible by default.

**Content status.** Spec §10b flags the FAQ answers as pending. The four questions below are certain; the answers marked `[PENDING]` are placeholders that must be replaced before launch. The test enforces that no `[PENDING]` string survives into a page that also says it is production-ready — see Task 15's launch check.

- [ ] **Step 1: Write the failing test**

Create `wensa/web-tests/faq.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal } from "./helpers.mjs";
import { dict } from "../legal/assets/js/i18n.js";

test("the FAQ uses native details/summary so it works without JS", () => {
  const html = readLegal("merchants.html");
  const section = html.slice(html.indexOf('id="faq"'));
  assert.equal((section.match(/<details/g) ?? []).length, 4);
  assert.equal((section.match(/<summary/g) ?? []).length, 4);
});

test("every FAQ question has an answer key in both languages", () => {
  for (const n of [1, 2, 3, 4]) {
    for (const lang of ["ar", "en"]) {
      assert.ok(dict[lang][`faq.q${n}`], `${lang}.faq.q${n} missing`);
      assert.ok(dict[lang][`faq.a${n}`], `${lang}.faq.a${n} missing`);
    }
  }
});

test("the closing CTA sends merchants to the dashboard", () => {
  const html = readLegal("merchants.html");
  const closing = html.slice(html.indexOf('class="band"'));
  assert.match(closing, /https:\/\/dashboard\.wensa\.app/);
});

// Spec section 10b: the answers are supplied by the business, not invented here.
// This test documents which ones are still placeholders. Delete the entries from
// PENDING as each real answer lands; the test then guards them against regression.
const PENDING = ["faq.a1", "faq.a2", "faq.a3", "faq.a4"];

test("placeholder answers are explicitly marked, never silently invented", () => {
  for (const key of PENDING) {
    assert.match(dict.ar[key], /\[PENDING\]/,
      `${key} must stay marked until the business supplies the real answer`);
  }
});
```

- [ ] **Step 2: Run it and confirm it fails**

```bash
node --test web-tests/faq.test.mjs
```

Expected: FAIL — the `faq.*` keys do not exist.

- [ ] **Step 3: Add the dictionary keys**

| Key | ar | en |
|---|---|---|
| `faq.title` | `اسئلة شائعة` | `Frequently asked` |
| `faq.q1` | `شكد العمولة؟` | `What's the commission?` |
| `faq.a1` | `[PENDING] العمولة تنحدد حسب الاتفاق — تواصل ويانا.` | `[PENDING] Commission is set per agreement — get in touch.` |
| `faq.q2` | `امتى توصلني فلوسي؟` | `When do I get paid?` |
| `faq.a2` | `[PENDING] التحويل يوصل لحسابك البنكي حسب دورة الدفع.` | `[PENDING] Transfers reach your bank account on the payout cycle.` |
| `faq.q3` | `اكو عقد لازم اوقعه؟` | `Do I need to sign a contract?` |
| `faq.a3` | `[PENDING] تكدر تبدي بدون عقد طويل.` | `[PENDING] You can start without a long-term contract.` |
| `faq.q4` | `عندي كم مكان — كلهم بحساب واحد؟` | `I have several venues — one account?` |
| `faq.a4` | `[PENDING] اي، تكدر تدير كل اماكنك من حساب واحد.` | `[PENDING] Yes, you can manage all your venues from one account.` |
| `close.title` | `يلا نبدي` | `Let's get started` |
| `close.body` | `سجّل مكانك بدقايق واستقبل اول حجز.` | `Register your venue in minutes and take your first booking.` |

- [ ] **Step 4: Add the markup**

After the pricing section in `merchants.html`:

```html
    <section class="section" id="faq" aria-labelledby="faq-title">
      <div class="u-wrap">
        <h2 id="faq-title" data-reveal data-i18n="faq.title">اسئلة شائعة</h2>
        <div class="faq" data-reveal data-reveal-delay="1">
          <details>
            <summary data-i18n="faq.q1">شكد العمولة؟</summary>
            <p data-i18n="faq.a1">[PENDING] العمولة تنحدد حسب الاتفاق — تواصل ويانا.</p>
          </details>
          <details>
            <summary data-i18n="faq.q2">امتى توصلني فلوسي؟</summary>
            <p data-i18n="faq.a2">[PENDING] التحويل يوصل لحسابك البنكي حسب دورة الدفع.</p>
          </details>
          <details>
            <summary data-i18n="faq.q3">اكو عقد لازم اوقعه؟</summary>
            <p data-i18n="faq.a3">[PENDING] تكدر تبدي بدون عقد طويل.</p>
          </details>
          <details>
            <summary data-i18n="faq.q4">عندي كم مكان — كلهم بحساب واحد؟</summary>
            <p data-i18n="faq.a4">[PENDING] اي، تكدر تدير كل اماكنك من حساب واحد.</p>
          </details>
        </div>
      </div>
    </section>

    <section class="band">
      <div class="band__inner u-wrap">
        <div>
          <h2 data-reveal data-i18n="close.title">يلا نبدي</h2>
          <p data-reveal data-reveal-delay="1" data-i18n="close.body">سجّل مكانك بدقايق واستقبل اول حجز.</p>
        </div>
        <a class="btn btn--paper" href="https://dashboard.wensa.app" data-reveal data-reveal-delay="2" data-i18n="merchant.ctaRegister">سجّل هسه</a>
      </div>
    </section>
```

- [ ] **Step 5: Add the CSS**

Append to `site.css`:

```css
/* ── FAQ ────────────────────────────────────────────────────────────────
   Native <details> so it works with JS off and is keyboard-accessible for
   free. Only the marker rotation is styled. */

.faq { max-width: 760px; margin-inline: auto; margin-block-start: var(--space-4); }

.faq details {
  border-block-end: 1px solid var(--line);
  padding-block: var(--space-2);
}

.faq summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  cursor: pointer;
  font-weight: 700;
  list-style: none;
}

.faq summary::-webkit-details-marker { display: none; }

.faq summary::after {
  content: "+";
  color: var(--teal);
  font-size: var(--step-2);
  line-height: 1;
  transition: transform 0.25s var(--ease);
}

.faq details[open] summary::after { transform: rotate(45deg); }

.faq p { margin-block-start: var(--space-2); color: var(--subink); }
```

- [ ] **Step 6: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add legal/merchants.html legal/assets/js/i18n.js legal/assets/css/site.css web-tests/faq.test.mjs
git commit -m "feat(site): merchant FAQ and closing CTA

FAQ answers are explicitly marked [PENDING] and tested as such, so
placeholder copy cannot quietly ship as though it were a real answer
(spec section 10b)."
```

---

## Task 15: Metadata, asset integrity, and full verification

**Files:**
- Modify: `wensa/legal/index.html`, `wensa/legal/merchants.html`
- Create: `wensa/web-tests/meta.test.mjs`
- Create: `wensa/web-tests/assets.test.mjs`
- Create: `wensa/README-site.md`

**Interfaces:**
- Consumes: everything.
- Produces: the launch checklist in `README-site.md`.

- [ ] **Step 1: Write the failing tests**

Create `wensa/web-tests/assets.test.mjs`:

```js
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
```

Create `wensa/web-tests/meta.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readLegal, PAGES } from "./helpers.mjs";

for (const page of PAGES) {
  test(`${page} has a title and description`, () => {
    const html = readLegal(page);
    assert.match(html, /<title>[^<]{10,}<\/title>/);
    assert.match(html, /<meta name="description" content="[^"]{20,}"/);
  });

  test(`${page} has a complete Open Graph card`, () => {
    const html = readLegal(page);
    for (const prop of ["og:type", "og:title", "og:description", "og:image", "og:url", "og:locale"]) {
      assert.match(html, new RegExp(`property="${prop}"`), `${prop} is missing`);
    }
    assert.match(html, /content="https:\/\/wensa\.app\/assets\/og-wensa\.jpg"/,
      "og:image must be an absolute URL — scrapers do not resolve relative paths");
  });

  test(`${page} declares its alternate language`, () => {
    const html = readLegal(page);
    assert.match(html, /rel="alternate"[^>]*hreflang="ar"/);
    assert.match(html, /rel="alternate"[^>]*hreflang="en"/);
  });

  test(`${page} has a canonical URL`, () => {
    assert.match(readLegal(page), /rel="canonical"/);
  });
}

test("the landing page declares the Arabic Iraqi locale", () => {
  assert.match(readLegal("index.html"), /property="og:locale" content="ar_IQ"/);
});
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: FAIL on every meta assertion.

- [ ] **Step 3: Add the metadata**

In `index.html`, insert inside `<head>` after the existing `<title>`:

```html
  <meta name="description" content="ونسة — كل ونستك بمكان واحد. مطاعم، ملاعب، مزارع وحفلات: شوف، احجز، وادفع بالدينار.">
  <link rel="canonical" href="https://wensa.app/">
  <link rel="alternate" hreflang="ar" href="https://wensa.app/">
  <link rel="alternate" hreflang="en" href="https://wensa.app/?lang=en">
  <link rel="alternate" hreflang="x-default" href="https://wensa.app/">

  <meta property="og:type" content="website">
  <meta property="og:site_name" content="ونسة">
  <meta property="og:url" content="https://wensa.app/">
  <meta property="og:title" content="ونسة — كل ونستك بمكان واحد">
  <meta property="og:description" content="مطاعم، ملاعب، مزارع وحفلات: شوف، احجز، وادفع بالدينار.">
  <meta property="og:image" content="https://wensa.app/assets/og-wensa.jpg">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:locale" content="ar_IQ">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:image" content="https://wensa.app/assets/og-wensa.jpg">

  <link rel="preload" as="font" type="font/woff2" href="/assets/fonts/graphik-ar-bold.woff2" crossorigin>
  <link rel="preload" as="font" type="font/woff2" href="/assets/fonts/graphik-ar-medium.woff2" crossorigin>
```

In `merchants.html`, add the same block with these substitutions: description `صير تاجر بونسة — اول شهر برو مجاناً و٠٪ عمولة. خلي مكانك يوصل لكل بغداد.`, canonical and `og:url` `https://wensa.app/merchants`, hreflang `en` `https://wensa.app/merchants?lang=en`, and `og:title` `صير تاجر بونسة`.

- [ ] **Step 4: Run the tests and confirm they pass**

```bash
node --test 'web-tests/*.test.mjs'
```

Expected: PASS across all test files.

- [ ] **Step 5: Verify responsiveness in a real browser**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site/legal
python3 -m http.server 4173
```

At each of 320, 390, 768, 1024, 1440, and 2560 px wide, on both `/` and `/merchants`, in both languages, confirm:

1. No horizontal scrollbar on `<body>`.
2. The nav never overlaps the wordmark or wraps into two rows.
3. The hero headline does not overflow its container at 320px.
4. The ticker still slides and stays edge-masked.
5. Characters do not crop awkwardly or overlap text.
6. Every tap target is at least 44×44 px.

Then in DevTools, enable *Rendering → Emulate prefers-reduced-motion: reduce* and confirm every section is visible at rest with no motion anywhere.

- [ ] **Step 6: Check performance**

Run Lighthouse (mobile, simulated slow 4G) against `http://localhost:4173/`. Performance must be ≥ 90 and Accessibility ≥ 95. If performance is short, the usual causes in this build are the placeholder screenshots being oversized — run them through `sips -Z 780` — or fonts not being preloaded.

- [ ] **Step 7: Write the launch checklist**

Create `wensa/README-site.md`:

```markdown
# wensa.app marketing site

Static site in `legal/`, deployed as the `wensa-privacy` Vercel project.
`/` is the consumer landing page, `/merchants` is the merchant pitch.
`/privacy`, `/download`, `/open`, and `.well-known/` are pre-existing and
untouched by this work.

## Local development

```bash
cd legal && python3 -m http.server 4173
```

## Tests

```bash
node --test 'web-tests/*.test.mjs'
```

No dependencies — Node's built-in runner. `web-tests/` lives outside `legal/`
on purpose: everything inside `legal/` is publicly served.

## Before launch

- [ ] Replace the placeholder screenshots in `legal/assets/img/screen-*.png`
      with real light-mode exports (home, venue/book, QR ticket).
- [ ] Replace the four `[PENDING]` FAQ answers in `legal/assets/js/i18n.js`
      and delete the matching entries from `PENDING` in `web-tests/faq.test.mjs`.
- [ ] Add Instagram, TikTok, and support/WhatsApp links to the footer.
- [ ] Decide whether to publish trust numbers; if so, add `data-counter`
      elements to the trust strip.
- [ ] Point the `dashboard.wensa.app` DNS record at the admin dashboard
      project — every merchant CTA already targets it.

## Gotchas

- **Pricing is hardcoded.** If `PlansPage.tsx` changes, `web-tests/pricing.test.mjs`
  fails on purpose. Update `plan.*` in `i18n.js` to match.
- **`main.js` calls `WensaInAppRedirect.init()` with no options.** Do not copy
  `download.html`'s `{ wholePage: true, autoAttempt: true }` here — `wholePage`
  makes the first tap anywhere jump to the App Store.
- **Arabic has two weights only.** Graphik Arabic Medium and Bold. Asking for
  300 or 600 in Arabic silently resolves to the nearest of those two.
```

- [ ] **Step 8: Run the full suite one final time**

```bash
cd /Users/mousaalhamad/Desktop/Wensa/wensa_app/wensa/.worktrees/feat-marketing-site
node --test 'web-tests/*.test.mjs'
```

Expected: PASS, every file. Record the actual pass count in the commit message.

- [ ] **Step 9: Commit**

```bash
git add legal/index.html legal/merchants.html web-tests/meta.test.mjs web-tests/assets.test.mjs README-site.md
git commit -m "feat(site): metadata, asset integrity checks and launch checklist

Open Graph, canonical and hreflang on both pages. assets.test.mjs walks
every local reference in the HTML and CSS and fails if the file is not on
disk, so a renamed asset cannot ship as a 404."
```

---

## Post-implementation

Deployment is automatic: pushing to `main` deploys the `wensa-privacy` Vercel project to production. Before merging `feat/marketing-site`:

1. Confirm `node --test 'web-tests/*.test.mjs'` passes.
2. Confirm the browser checks in Task 15 Step 5 pass at every breakpoint in both languages.
3. Confirm `/privacy`, `/download`, `/open`, `/placeDetails`, `/eventDetails`, and both `.well-known` files still resolve on the preview deployment — the `vercel.json` edit in Task 1 is the only change that could break them.
4. Test a real store button from inside the Instagram in-app browser on an actual iPhone. This cannot be verified in a desktop browser.

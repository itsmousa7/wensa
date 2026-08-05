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
- [ ] Fix the nav overflow at 320px width: `.nav__actions` (language toggle +
      merchant CTA pill) doesn't fit next to the wordmark at exactly 320px on
      either page, in either language, causing a horizontal scrollbar. Fine
      at 390px and up. Traces to the shared nav shell CSS (`.nav__actions` in
      `site.css`), not anything page-specific.
- [ ] Finish the tap-target audit sitewide. `.btn` now has `min-height: 44px`
      (final review fix wave), but footer/nav text links still render at
      ~22–25px, and the in-app-browser redirect toast's close/copy-link
      controls (`inapp-redirect.js`) are well under 44px.
- [ ] Fix the nav overflow at 320px width: `.nav__actions` (language toggle +
      merchant CTA pill) doesn't fit next to the wordmark at exactly 320px on
      either page, in either language, causing a horizontal scrollbar. Fine
      at 390px and up. Traces to the shared nav shell CSS (`.nav__actions` in
      `site.css`), not anything page-specific. Left out of the final review's
      fix wave deliberately — it needs a real layout redesign, not a quick
      patch.

## Gotchas

- **Pricing is hardcoded.** If `PlansPage.tsx` changes, `web-tests/pricing.test.mjs`
  fails on purpose. Update `plan.*` in `i18n.js` to match.
- **`main.js` calls `WensaInAppRedirect.init()` with no options.** Do not copy
  `download.html`'s `{ wholePage: true, autoAttempt: true }` here — `wholePage`
  makes the first tap anywhere jump to the App Store.
- **Arabic has two weights only.** Graphik Arabic Medium and Bold. Asking for
  300 or 600 in Arabic silently resolves to the nearest of those two.
- **`character-register.png` and `character-thumbsup.png` are palette-quantized,
  then re-encoded back to RGBA** — not raw `tools/cutout.py` output. This is
  specifically to clear `/merchants`' Lighthouse performance gate, which
  currently passes with a real but nontrivial margin (91, up from 81 before
  quantization). Re-running `tools/cutout.py` and committing its raw output
  would silently regrow these files and regress that page's performance score.
  See the plan's Task 15 Step 6 (`docs/superpowers/plans/2026-08-05-wensa-marketing-site.md`)
  for the full technique, the exact Pillow invocation, and why plain palette
  mode (color type 3) isn't shippable here.
- **`tools/cutout.py` requires `rembg`**, which is not in any manifest — per
  the plan's Task 10 and Task 15 sections, it's installed into a throwaway
  venv to run the script and then discarded, the same pattern as the font
  conversion in Task 2.
- **The three `legal/assets/img/screen-*.png` placeholder screenshots are
  currently byte-identical** — all three render the same "SCREENSHOT PENDING"
  placeholder graphic. Useful to know before replacing them: there is no
  per-screen content to preserve, each just needs to become its own real
  export.

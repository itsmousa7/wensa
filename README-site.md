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

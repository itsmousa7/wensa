# Wensa Marketing Site — Design

**Date:** 2026-08-05
**Status:** Approved, ready for implementation plan
**Location:** `wensa/legal/` (the `wensa-privacy` Vercel project, serving `wensa.app`)

---

## 1. Goal

A public marketing site at `wensa.app` with two audiences:

- **Consumers** — learn what Wensa is, then download the iOS or Android app.
- **Merchants** — learn how to join and what they get, then register at the merchant dashboard.

Arabic (Iraqi dialect) is the default language; English is a toggle. The site is
heavily animated, fully responsive, and must survive being opened inside the
Instagram and TikTok in-app browsers.

---

## 2. Where it lives

The site is added to the existing `legal/` folder, which is already deployed as the
`wensa-privacy` Vercel project on `wensa.app`. This keeps one domain, leaves the
working legal and deep-link pages untouched, and lets the new pages reuse
`inapp-redirect.js` directly.

```
wensa/legal/
├── index.html          NEW  landing page (AR default, dir="rtl")
├── merchants.html      NEW  become-a-merchant page
├── privacy.html             unchanged
├── download.html            unchanged
├── open.html                unchanged
├── favicon.ico              unchanged
├── .well-known/             unchanged (apple-app-site-association, assetlinks.json)
├── assets/
│   ├── inapp-redirect.js    unchanged — reused by both new pages
│   ├── wensa-logo.png       unchanged
│   ├── icon-192.png icon-512.png apple-touch-icon.png og-wensa.jpg   unchanged
│   ├── site.css        NEW  design tokens + every section style
│   ├── site.js         NEW  motion engine
│   ├── i18n.js         NEW  AR/EN dictionary + direction toggle
│   ├── fonts/          NEW  self-hosted WOFF2
│   └── img/            NEW  cut-out characters, app screens, QR code
│                            (category icons are inline SVG in the HTML)
└── vercel.json         EDIT drop the "/" → "/privacy" redirect
```

### vercel.json change

The single edit is removing this redirect so `/` serves the new landing page:

```json
"redirects": [
  { "source": "/", "destination": "/privacy", "permanent": false }
]
```

`cleanUrls`, the `.well-known` headers, and the `/placeDetails` + `/eventDetails`
rewrites all stay exactly as they are.

### No build step

Plain HTML, CSS, and ES-module JavaScript. This matches how the project already
deploys, adds no toolchain, and keeps the payload near 60 KB of CSS+JS — which
matters on Iraqi mobile networks.

---

## 3. Bilingual model

`<html lang="ar" dir="rtl">` is the served default. The toggle:

1. Flips `lang` and `dir` on `<html>`.
2. Swaps the text of every `[data-i18n]` node from the dictionary in `i18n.js`.
3. Swaps the font stack via a CSS custom property bound to `[lang]`.
4. Persists the choice in `localStorage` under `wensa_lang`.
5. Reflects the choice as `?lang=en` so a link can be shared in either language.

No reload and no flash of the wrong language: `i18n.js` is a blocking classic
script in `<head>` that reads `localStorage`/`?lang` and sets `lang`/`dir` before
first paint.

**Copy rules** (from `WENSA_BRAND_SKILL.md` §9): Iraqi dialect, not فصحى. Use
`اكو/ماكو`, `هواي`, `شلون`, `شنو`, `وين`, `يلا`, `هسه`. Arabic-Indic numerals
`٠١٢٣٤٥٦٧٨٩` in Arabic copy. Currency as IQD / د.ع.

---

## 4. Design system

### Color (canonical, from `WENSA_BRAND_SKILL.md` §3)

| Token | Hex | Role |
|---|---|---|
| `--paper` | `#FBFAF8` | Page canvas |
| `--ink` | `#18262B` | Headlines, primary text |
| `--subink` | `#6C7A7E` | Sub-copy, fine print |
| `--teal` | `#3490A2` | The single accent: wordmark, buttons, bullets, underlines |
| `--orange` | `#FF6F3C` | Exactly one hit per page — the merchant offer badge |
| `--yellow` | `#FFD93D` | Optional single spark |

White canvas with generous negative space. One accent per screen. Type is the art.

### Typography

Arabic uses Graphik Arabic, English uses IBM Plex Sans, both self-hosted as WOFF2.

**Correction to the available Graphik files.** `wensa/assets/fonts/` nominally holds
four faces, but:

- `graphik-bold.ttf` and `graphik-extra-bold.ttf` are byte-identical (286,588 bytes,
  both report the internal name *Graphik Arabic Bold*).
- `graphik-light.ttf` reports the internal name *Graphik Arabic Medium*.
- `ibm-bold.ttf` is *IBM Plex Sans **Condensed** Bold* and contains **zero** Arabic
  codepoints.

So the real inventory is **two** Arabic weights: Medium and Bold. The Arabic type
hierarchy is built on those two only. For English, the full IBM Plex Sans family
(300/400/500/600/700) is self-hosted from Google Fonts — it is OFL-licensed, so this
is legally clean and gives real weights instead of one condensed bold.

| Role | Arabic | English |
|---|---|---|
| Hero headline | Graphik Arabic Bold | IBM Plex Sans 700 |
| Section heading | Graphik Arabic Bold | IBM Plex Sans 600 |
| Body / sub-copy | Graphik Arabic Medium | IBM Plex Sans 400 |
| Fine print | Graphik Arabic Medium | IBM Plex Sans 300 |

TTF sources are converted to WOFF2 at build-prep time and committed. All faces load
with `font-display: swap` and are preloaded for the above-the-fold weights.

### Layout

Fluid type via `clamp()`. 8 px spacing scale. Content max-width 1200 px with a
1.5 rem gutter on mobile. Breakpoints at 640 / 900 / 1200 px. Logical CSS properties
throughout (`margin-inline-start`, `padding-inline`, `inset-inline-end`) so a single
stylesheet serves both directions with no RTL override sheet.

### Structural inspiration

Wayl (`wayl.io`) informs the *structure*, not the look: white canvas, huge negative
space, product cards built around real screenshots, a benefits grid, transparent
pricing, and one strong closing CTA band. Palette, typography, and voice stay Wensa's.

---

## 5. Landing page — `index.html`

| # | Section | Content |
|---|---|---|
| 1 | Sticky nav | Teal wordmark (inline-start), section links, `عربي/EN` pill, solid teal **صير تاجر بونسة** → `/merchants`. Blurs and shrinks past 40 px scroll. |
| 2 | Hero | Rotating-word headline (below), sub-line, App Store + Google Play buttons, phone frame with scroll parallax. |
| 3 | Category ticker | The app's 9 real categories, sliding right→left. |
| 4 | What you can do | `شنو تكدر تسوي بونسة؟` — three product cards: discover / book / QR ticket, each with a real app screen. |
| 5 | How it works | Three numbered steps joined by an SVG line that draws on scroll. |
| 6 | Trust strip | `دفع بالدينار · تذكرة QR · إلغاء سهل`, plus counters if real numbers are supplied. |
| 7 | Download | Thumbs-up character (cut out), both store buttons, QR code for desktop visitors. |
| 8 | Merchant band | Teal panel — `عندك مطعم او ملعب؟ اول شهر علينا.` → `/merchants`. |
| 9 | Footer | Wordmark, privacy link, download link, socials, `wensa.app`. |

### Hero rotating word

```
احجز [ بادل · مطعم · مزرعة · حفلة · جم ] بثانية وحدة
```

The bracketed word cycles every 2.2 s. The outgoing word translates up and out
behind a clipping mask while the incoming word rises into place, on
`cubic-bezier(0.22, 1, 0.36, 1)`. The slot's width animates to the new word's
measured width so the surrounding line reflows smoothly rather than jumping. Widths
are measured once on load into a hidden mirror element. The English rotation is
`padel · a table · a farm · a concert · a gym`.

### Category ticker

The nine categories are the ones the app's home screen actually renders
(`category_bar.dart`): رياضة · مطاعم · موسيقى · مولات · كافيهات · سينما · مهرجانات ·
مزارع · خصومات.

Implementation: one flex row containing the set duplicated twice, translated by
`-50%` over a linear loop, giving a seamless cycle with no JS ticking. Direction is
right→left in both languages. `mask-image` fades both edges into the canvas.
Pauses on hover and on focus-within. Each item is an icon plus its label; icons are
inline SVG derived from the app's Lottie category assets (no runtime Lottie library,
so nothing is added to the bundle).

---

## 6. Merchants page — `merchants.html`

| # | Section | Content |
|---|---|---|
| 1 | Nav | Same as landing; primary CTA becomes **سجّل هسه** → `https://dashboard.wensa.app`. |
| 2 | Hero | Notebook character (cut out), headline `خلي مكانك يوصل لكل بغداد`, orange offer badge, CTAs `سجّل هسه` + `شوف الاسعار`. |
| 3 | The offer | Single large card — see wording below. |
| 4 | Benefits | Six cards: reach app users · bookings 24/7 · paid in IQD · QR check-in at the door · real analytics · banners and promotion. |
| 5 | How to join | Four steps with the same SVG line-draw: register → add your place and photos → we review and verify → go live and take bookings. |
| 6 | Pricing | Three real plan cards (below). |
| 7 | FAQ | Accordion. **Content pending — see §10.** |
| 8 | Closing CTA | Teal band → `https://dashboard.wensa.app`. |

### The offer — exact wording

Both perks cover **month one only**, and the free plan must be stated so no merchant
believes a paid plan is mandatory.

- **Headline:** `اول شهر برو مجاناً + ٠٪ عمولة`
- **Body:** first month on the Pro plan is free and takes 0% commission.
- **Fine print:** after the first month, Pro is 60,000 د.ع per month and standard
  commission applies.
- **Reassurance line (required):** there is always a free Basic plan — you are never
  forced onto a paid plan.

### Pricing — real data

Pulled from `wansa-admin-dashboard/src/features/merchant/PlansPage.tsx`. Both
language variants already exist there and are copied verbatim.

| Plan | Price | Features (EN) |
|---|---|---|
| **Basic** — أساسي | Free / مجاني | 2 combined places & events · 3 additional photos · Basic listing · No free banners (5,000 IQD each) |
| **Growth** — نمو *(الأكثر شيوعاً)* | 25,000 IQD/mo | 10 combined places & events · Unlimited photos · Direct contact button · Basic analytics · 3 free banners/month + 5,000 IQD each after |
| **Pro** — احترافي | 60,000 IQD/mo | Unlimited places & events · Advanced analytics · Priority placement · Verified badge · Home feed promotion · Multi-staff access · 10 free banners/month + 5,000 IQD each after |

Growth carries the `الأكثر شيوعاً` badge, matching the dashboard. Pro carries a note
that month one is free.

If these numbers change in the dashboard, they must be updated here too — the site
hardcodes them rather than fetching, since the site has no backend.

---

## 7. Characters

`Wensa_Marketing_Campaign/characters/` holds two renders, both on solid off-white
backgrounds:

- `thumb_okay_posture.png` — thumbs-up woman → landing page download section.
- `register.PNG` — man with a notebook → merchants page hero.

Both are background-removed to transparent PNG before use, exported at 2× for retina,
and given a gentle scroll parallax. They are bottom-anchored within their sections.

---

## 8. Motion

| Effect | Technique |
|---|---|
| Rotating hero word | Clip-mask + `translateY`, 2.2 s cycle, width animated to measured target |
| Category ticker | CSS `translateX(-50%)` linear loop over a duplicated track |
| Scroll reveals | `IntersectionObserver`, staggered `translateY(16px)` + fade, `ease-out-cubic` |
| Phone + character parallax | `transform: translate3d()` driven by a single rAF-throttled scroll listener |
| Step connectors | SVG `stroke-dashoffset` animated as the section enters |
| Nav | Backdrop blur + height reduction past 40 px |
| Buttons | Lift on hover with a soft teal glow; press state returns to rest |
| Trust counters | Roll-up from 0 on first entry, once only |

Easing and pacing follow `WENSA_BRAND_SKILL.md` §8 — calm and confident, nothing
bouncy or frantic. Every effect collapses to its end state under
`@media (prefers-reduced-motion: reduce)`. All animation is on `transform` and
`opacity` only; no property that triggers layout is animated.

---

## 9. Download and in-app browser handling

Both new pages include `assets/inapp-redirect.js` **unchanged**. Every store button
carries `data-store-cta="ios"` or `data-store-cta="android"` with the live store URL:

- iOS — `https://apps.apple.com/iq/app/wensa-%D9%88%D9%86%D8%B3%D8%A9/id6780271862`
- Android — `https://play.google.com/store/apps/details?id=app.wensa.mobile`

### Initialisation differs from `/download` — deliberately

`download.html` calls `init({ wholePage: true, autoAttempt: true })`. That is correct
for a dedicated download page where the visitor's only intent is to install, but wrong
for a marketing page: `wholePage` makes the *first tap anywhere* jump to the App
Store, which would break navigation, and `autoAttempt` would fire an escape on load
before the visitor has read anything.

The new pages therefore call:

```js
WensaInAppRedirect.init();   // no options
```

This intercepts taps on `[data-store-cta]` anchors only. Resulting behaviour:

| Environment | Behaviour |
|---|---|
| Instagram / Threads / Facebook on iOS | `instagram://extbrowser` or `x-safari-` handoff to the real browser |
| Any Android in-app webview | `intent://…#Intent;scheme=https;end` |
| TikTok, Snapchat, others on iOS | No working escape exists — falls through to plain anchor navigation to the store |
| Real browsers | Untouched; the anchor navigates normally |

If an escape does not visibly succeed within 1.5 s, the script's existing Arabic
bottom-sheet appears with a retry button, manual instructions, and a copy-link
control. No new detection logic is written — the existing module already handles
every case, including the `musical_ly` UA quirk for TikTok on iOS.

---

## 10. Open items

These do not block implementation. Each is built with a clearly-marked placeholder
and swapped when the asset arrives.

**a. Clean app screenshots.** `build.py` sourced screenshots from
`/Users/mousaalhamad/Desktop/app_images`, which no longer exists. The only raw shots
remaining are `ruler_*.png` — dark mode with red measurement lines drawn over them,
and only four of them. Five fresh light-mode iPhone screenshots are needed: home,
venue, booking/date, checkout, QR ticket. **Fallback if not supplied:** crop the
device out of `wensa_appstore_mockups/out/*.png`, which carries baked-in English
marketing text and will read poorly on an Arabic page.

**b. FAQ content** for the merchants page — commission rate, payout timing, whether a
contract is required, whether several venues fit under one account.

**c. Footer contacts** — Instagram handle, TikTok handle, support/WhatsApp number.

**d. Trust numbers** — venues live, cities covered, bookings to date. If not supplied,
the counter row is dropped and the strip keeps only the three qualitative claims.

---

## 11. Non-goals

- No CMS, no backend, no database. Content is authored directly in the HTML.
- Pricing is hardcoded, not fetched from Supabase.
- No blog, no careers page, no merchant login form on this site — sign-in lives
  entirely in the dashboard.
- `privacy.html`, `download.html`, `open.html`, and `.well-known/` are not modified.
- `inapp-redirect.js` is not modified.

---

## 12. Acceptance criteria

1. `wensa.app/` serves the Arabic landing page; `wensa.app/merchants` serves the
   merchant page. `/privacy`, `/download`, `/open`, and both `.well-known` files
   continue to resolve exactly as before.
2. The language toggle switches all copy and flips direction with no reload and no
   flash of the wrong language on first paint.
3. The hero word rotates and the category ticker loops seamlessly, both pausing
   appropriately, in both directions.
4. Every animation collapses to its end state under `prefers-reduced-motion: reduce`.
5. Layout holds with no horizontal overflow from 320 px to 2560 px wide.
6. Tapping a store button inside the Instagram in-app browser on iOS escapes to
   Safari; inside TikTok it navigates to the store or shows the fallback sheet.
7. The merchant CTA links to `https://dashboard.wensa.app`.
8. Pricing on `/merchants` matches `PlansPage.tsx` exactly, and the free-Basic-plan
   reassurance line is present.
9. Lighthouse mobile performance ≥ 90 on a simulated slow 4G connection.

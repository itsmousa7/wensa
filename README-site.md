# wensa.app marketing site — moved

This used to live in `legal/` here, deployed as the `wensa-privacy` Vercel
project. It's been split into three independent sibling repos, one
directory up from this Flutter app:

- `../wensa-website` — the landing page, merchant pitch, and the
  app-deep-link redirect page (`index.html`, `merchants.html`, `open.html`),
  plus `web-tests/` and `tools/cutout.py`.
- `../wensa-privacy` — the privacy policy page.
- `../wensa-download` — the app-download page.

See each repo's own `README.md` for local development, tests, and what
still needs setting up (each needs its own Vercel project — moving the
source out from under the old `wensa-privacy` project broke its git-push
auto-deploy connection).

The historical planning doc for the original build is still at
`docs/superpowers/plans/2026-08-05-wensa-marketing-site.md` in this repo.

# Onboarding Lottie animations

These three files drive the onboarding slides. They are **dotLottie** (`.lottie`)
files — a zipped, minified container that is much smaller than raw Lottie JSON.
They were sourced from the LottieFiles public catalog (free animations) and
matched to each slide's theme.

| File | Slide | Theme | LottieFiles name |
|------|-------|-------|------------------|
| `discover.lottie` | 1 — Discover | family road trip / car | "travel in car" |
| `venues.lottie`   | 2 — Book & tickets | sports / football pitches | "playing football" |
| `joy.lottie`      | 3 — All the fun (ونسة) | celebration / joy | "celebration" |

## dotLottie packaging note

The `lottie` Flutter package auto-detects `.lottie` (zip) files and picks the
**first** `*.json` entry in the archive as the animation. A standard LottieFiles
`.lottie` lists `manifest.json` first, which the package would wrongly parse as
the animation. So each file here is repackaged with the animation JSON placed
**first** (`animations/data.json`), followed by `manifest.json`. Keep that
ordering if you regenerate these.

## Replacing an animation

Download a free animation from https://lottiefiles.com/free-animations, then
repackage it as a `.lottie` with the animation JSON first. Good search terms:

- **discover.lottie** — "family road trip", "travel in car", "car vacation"
- **venues.lottie** — "football soccer play", "padel tennis", "stadium"
- **joy.lottie** — "celebration party fun", "happy people enjoy"

The UI degrades gracefully: if a file is missing or invalid, the slide shows an
on-theme gradient icon instead (see `OnboardingVisual`).

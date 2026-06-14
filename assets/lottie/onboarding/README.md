# Onboarding Lottie animations

These three files drive the onboarding slides. They were fetched from the
LottieFiles public catalog (free animations) and matched to each slide's theme.

| File | Slide | Theme | LottieFiles name |
|------|-------|-------|------------------|
| `discover.json` | 1 — Discover | location / explore | "Comp 1" (explore) |
| `venues.json`   | 2 — Book & tickets | sports / football pitches | "playing football" |
| `joy.json`      | 3 — All the fun (ونسة) | celebration / joy | "celebration" |

## Replacing an animation

To swap any of these, download a free Lottie **JSON** from
https://lottiefiles.com/free-animations and save it over the matching filename
above (keep the same name). Good search terms per slide:

- **discover.json** — "explore", "discover places", "location map", "city explore pin"
- **venues.json** — "football soccer play", "padel tennis", "stadium", "sport event ticket"
- **joy.json** — "celebration party fun", "happy people enjoy", "one tap mobile app"

The UI degrades gracefully: if a file is missing or invalid, the slide shows an
on-theme gradient icon instead (see `OnboardingVisual`).

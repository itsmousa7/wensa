# Google Play — Data safety declaration (Wensa app)

Source of truth for the Play Console **App content → Data safety** form. Google
holds the developer responsible for keeping this accurate, so update this file
in the same PR as any change that adds, removes, or repurposes collected data.

Version 1.0.1 (`versionCode` 10) was rejected because **Personal info → Email
address** was transmitted off device but not declared. The table below is the
full inventory, so the resubmission does not fail again on a second data type.

## Backends the app talks to

| Destination | What goes there | Whose |
|---|---|---|
| Supabase (`qvozjwlkzordudkhamcu`) | account, profile, bookings, avatars, FCM tokens | ours (processor) |
| Firebase Cloud Messaging | device push token | Google |
| HyperPay | card details, entered in the app's own card form and passed to the HyperPay SDK | third-party PSP |

No analytics, crash-reporting, advertising, or attribution SDK is present —
`pubspec.yaml` has only `firebase_core` and `firebase_messaging`. No location
permission is requested and no geolocation API is called.

## Data types to declare as COLLECTED

All are transmitted off device. All are encrypted in transit. None are
ephemeral-only.

| Google data type | Category | Where it comes from | Purpose | Optional? |
|---|---|---|---|---|
| **Email address** | Personal info | email signup/sign-in, Google Sign-In, Apple Sign-In → `profiles.app_users.email` | Account management, App functionality | Required |
| **Name** | Personal info | `first_name` / `second_name` in the complete-profile and booking flows | Account management, App functionality | Required |
| **Phone number** | Personal info | `phone`, collected in the booking flow | App functionality (booking contact) | Required |
| **User IDs** | Personal info | Supabase `auth.users` UUID | Account management, App functionality | Required |
| **Photos** | Photos and videos | optional avatar via `ImagePicker` → Supabase Storage `avatars` bucket | App functionality | Optional |
| **Purchase history** | Financial info | bookings and memberships created by the user | App functionality | Required |
| **Device or other IDs** | Device or other IDs | FCM registration token → `profiles.user_fcm_tokens` | App functionality (push notifications) | Required |

Account deletion is offered in-app (the `delete-account` edge function), so
answer **yes** to "users can request that their data be deleted".

## Judgement calls worth reading before you submit

- **Payment info — RE-CHECK THIS.** The app now renders its OWN card form
  (`card_payment_screen.dart`) and hands the PAN, expiry and CVV to the native
  HyperPay SDK through `hyperpay_channel.dart`. Card data therefore passes
  through Dart, unlike the earlier hosted-checkout arrangement this file used to
  describe. It is never stored and never reaches our backend, but *Payment info
  → collected, not shared, App functionality* is now the defensible answer.
  Confirm before the next submission.
- **"Shared" vs "collected".** Supabase and Firebase process data on our behalf,
  which Google treats as collection rather than sharing. HyperPay is an
  independent processor for payments. Confirm against Google's current
  definitions — this is a policy question, not an engineering one.
- **Avatars are world-readable.** `uploadAvatar` returns `getPublicUrl`, so the
  `avatars` bucket serves unauthenticated URLs. That is a product decision, not
  a form field, but it is worth knowing when answering the security questions.

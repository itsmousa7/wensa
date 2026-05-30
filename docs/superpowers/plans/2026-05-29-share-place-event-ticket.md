# Share: Places, Events & Tickets — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add share buttons to the place, event, and ticket detail pages that open the native share sheet with a branded image (and, for places/events, a caption + placeholder link), and track `shares_count` for analytics.

**Architecture:** Dedicated fixed-width "share card" widgets are rendered off-screen to PNG (via `screenshot`), written to a temp file, and shared via `share_plus`. Places/events pre-fetch their cover image bytes (via `http`) so the network image rasterizes reliably. A shared `ShareService` centralizes render + share + fetch. The existing ticket visual is extracted into a reusable `TicketCard` so the on-screen ticket and the shared image stay identical.

**Tech Stack:** Flutter, Riverpod, Supabase, `share_plus`, `path_provider`, `screenshot`, `qr_flutter`, `http`, `intl`.

**Spec:** `docs/superpowers/specs/2026-05-29-share-place-event-ticket-design.md`

**Conventions in this repo:**
- Package name is `future_riverpod` (imports are `package:future_riverpod/...`).
- Localization uses a `bool isAr`/`isArabic` derived from `appLocaleProvider` (places/events) or `Localizations.localeOf(context).languageCode == 'ar'` (ticket).
- Colors live in `lib/core/constants/theme/app_colors.dart` (`AppColors`).
- Fire-and-forget analytics calls use `.ignore()` (see existing `recordView`).

---

## File Structure

**Create:**
- `lib/core/share/share_link.dart` — URL + caption pure helpers (testable).
- `lib/core/share/share_service.dart` — render-to-png + share + fetch-bytes.
- `lib/core/share/branded_header.dart` — `BrandedHeader` (app icon + WENSA).
- `lib/core/share/content_share_card.dart` — `ContentShareCard` reused by place & event.
- `lib/features/bookings_history/presentation/widgets/ticket_card.dart` — `TicketInfoCell`, `TicketCard`, `ShareableTicketCard` (extracted from the page).
- `assets/icons/app_icon.png` — copied from the iOS app icon.
- `supabase/migrations/20260529000000_increment_event_share_count.sql` — event share RPC.
- `test/core/share/share_link_test.dart` — unit tests for `share_link.dart`.
- `test/core/share/content_share_card_test.dart` — smoke test.

**Modify:**
- `lib/features/places/domain/repositories/place_details_repository.dart` — add `recordShare`.
- `lib/features/events/domain/repositories/events_repository.dart` — add `recordShare`.
- `lib/features/places/presentation/pages/place_details_page.dart` — share button + handler.
- `lib/features/events/presentation/pages/event_details_page.dart` — share button + handler.
- `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` — use `TicketCard`, add Share button + handler.
- `pubspec.yaml` — add 3 dependencies.

---

## Task 1: Add dependencies and the brand asset

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/icons/app_icon.png`

- [ ] **Step 1: Add the packages**

Run (from repo root):
```bash
flutter pub add share_plus path_provider screenshot
```
Expected: `pubspec.yaml` gains `share_plus`, `path_provider`, `screenshot` under dependencies; `flutter pub get` succeeds.

- [ ] **Step 2: Copy the app icon into Flutter assets**

Run:
```bash
cp "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" assets/icons/app_icon.png
```
The `assets/icons/` folder is already declared in `pubspec.yaml`, so no manifest edit is needed.

- [ ] **Step 3: Verify it resolves**

Run:
```bash
flutter pub get && ls assets/icons/app_icon.png
```
Expected: file exists; no dependency errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/icons/app_icon.png
git commit -m "chore: add share_plus, path_provider, screenshot and brand asset"
```

---

## Task 2: Share link & caption helpers (TDD)

**Files:**
- Create: `lib/core/share/share_link.dart`
- Test: `test/core/share/share_link_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/share/share_link_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/core/share/share_link.dart';

void main() {
  test('placeShareUrl builds a placeId query url', () {
    expect(placeShareUrl('abc'), 'https://wensa.app/place?placeId=abc');
  });

  test('eventShareUrl builds an eventId query url', () {
    expect(eventShareUrl('e1'), 'https://wensa.app/event?eventId=e1');
  });

  test('placeShareCaption (en) includes name and url', () {
    final c = placeShareCaption(name: 'Cafe X', id: 'abc', isAr: false);
    expect(c, 'Check out Cafe X on Wensa!\nhttps://wensa.app/place?placeId=abc');
  });

  test('placeShareCaption (ar) includes name and url', () {
    final c = placeShareCaption(name: 'مقهى', id: 'abc', isAr: true);
    expect(c, contains('مقهى'));
    expect(c, contains('https://wensa.app/place?placeId=abc'));
  });

  test('eventShareCaption (en) includes name and url', () {
    final c = eventShareCaption(name: 'Show', id: 'e1', isAr: false);
    expect(c, 'Check out Show on Wensa!\nhttps://wensa.app/event?eventId=e1');
  });

  test('ticketShareCaption (en) includes name', () {
    expect(ticketShareCaption(name: 'Arena', isAr: false), contains('Arena'));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/share/share_link_test.dart`
Expected: FAIL — `Target of URI doesn't exist 'package:future_riverpod/core/share/share_link.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/share/share_link.dart
//
// Centralized share URLs + captions. The base URL is a placeholder until a
// real domain + deep linking is set up — change kShareBaseUrl in one place.

/// Base URL for shareable links. Placeholder until a real domain is purchased
/// and universal/app links are configured.
const String kShareBaseUrl = 'https://wensa.app';

String placeShareUrl(String id) => '$kShareBaseUrl/place?placeId=$id';

String eventShareUrl(String id) => '$kShareBaseUrl/event?eventId=$id';

String placeShareCaption({
  required String name,
  required String id,
  required bool isAr,
}) => isAr
    ? 'شِف $name على ونسة!\n${placeShareUrl(id)}'
    : 'Check out $name on Wensa!\n${placeShareUrl(id)}';

String eventShareCaption({
  required String name,
  required String id,
  required bool isAr,
}) => isAr
    ? 'شِف $name على ونسة!\n${eventShareUrl(id)}'
    : 'Check out $name on Wensa!\n${eventShareUrl(id)}';

String ticketShareCaption({required String name, required bool isAr}) => isAr
    ? 'تذكرتي إلى $name عبر ونسة 🎟️'
    : 'My ticket to $name via Wensa 🎟️';
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/share/share_link_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/share/share_link.dart test/core/share/share_link_test.dart
git commit -m "feat(share): add share url and caption helpers"
```

---

## Task 3: ShareService (render + share + fetch)

**Files:**
- Create: `lib/core/share/share_service.dart`

> Native share + off-screen rendering can't be meaningfully unit-tested; verify by `flutter analyze` here and manually in Task 11.

- [ ] **Step 1: Write the implementation**

```dart
// lib/core/share/share_service.dart
//
// Single entry point for sharing: render a widget to PNG off-screen, share an
// image (or text) via the native sheet, and fetch remote image bytes.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController _controller = ScreenshotController();

  /// Rasterize [card] off-screen at [pixelRatio]. The card is wrapped with the
  /// current Theme, the correct Directionality (RTL/LTR), a neutral MediaQuery
  /// (textScaler fixed to 1.0 so the image looks consistent), and a transparent
  /// Material. [delay] lets post-frame layout (e.g. ticket tear-line) settle.
  Future<Uint8List> renderToPng(
    BuildContext context,
    Widget card, {
    required bool isAr,
    double pixelRatio = 3,
    Duration delay = const Duration(milliseconds: 200),
  }) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final wrapped = MediaQuery(
      data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Theme(
          data: theme,
          child: Material(type: MaterialType.transparency, child: card),
        ),
      ),
    );
    return _controller.captureFromLongWidget(
      InheritedTheme.captureAll(context, wrapped),
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
    );
  }

  /// Share a PNG with an optional [caption]. Writes a temp file first (most
  /// reliable across platforms). Returns the platform [ShareResult].
  Future<ShareResult> shareImage(
    BuildContext context,
    Uint8List png, {
    required String caption,
    String fileName = 'wensa_share.png',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(png, flush: true);
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        text: caption,
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  Future<ShareResult> shareText(BuildContext context, String text) {
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  /// Fetch remote image bytes (for cover images that must rasterize in an
  /// off-screen capture). Returns null on any failure — callers fall back.
  Future<Uint8List?> fetchImageBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}
```

- [ ] **Step 2: Verify it analyzes clean**

Run: `flutter analyze lib/core/share/share_service.dart`
Expected: No issues (no missing imports/types).

- [ ] **Step 3: Commit**

```bash
git add lib/core/share/share_service.dart
git commit -m "feat(share): add ShareService for render/share/fetch"
```

---

## Task 4: BrandedHeader widget

**Files:**
- Create: `lib/core/share/branded_header.dart`

- [ ] **Step 1: Write the implementation**

```dart
// lib/core/share/branded_header.dart
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

/// "[app icon] WENSA" header used at the top of all shareable images.
class BrandedHeader extends StatelessWidget {
  const BrandedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.lightGreenPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icons/app_icon.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'WENSA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: brand,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it analyzes clean**

Run: `flutter analyze lib/core/share/branded_header.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/share/branded_header.dart
git commit -m "feat(share): add BrandedHeader for shareable images"
```

---

## Task 5: ContentShareCard (place & event) + smoke test

**Files:**
- Create: `lib/core/share/content_share_card.dart`
- Test: `test/core/share/content_share_card_test.dart`

- [ ] **Step 1: Write the implementation**

```dart
// lib/core/share/content_share_card.dart
//
// Fixed-width branded card used for sharing a place or an event as an image.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/share/branded_header.dart';

class ContentShareCard extends StatelessWidget {
  const ContentShareCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isAr,
    required this.footerText,
    this.coverBytes,
  });

  final String name;
  final String subtitle;
  final bool isAr;
  final String footerText;
  final Uint8List? coverBytes;

  static const double _width = 360;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandedHeader(),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: _Cover(coverBytes: coverBytes, name: name),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreenPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              footerText,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightGreenSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.coverBytes, required this.name});
  final Uint8List? coverBytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (coverBytes != null) {
      return Image.memory(coverBytes!, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightGreenPrimary,
            AppColors.lightGreenSecondary,
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write a smoke test**

```dart
// test/core/share/content_share_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/core/share/content_share_card.dart';

void main() {
  testWidgets('ContentShareCard renders name, subtitle and footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentShareCard(
            name: 'Cafe X',
            subtitle: 'Karrada, Baghdad',
            isAr: false,
            footerText: 'Discover on Wensa',
          ),
        ),
      ),
    );
    expect(find.text('Cafe X'), findsOneWidget);
    expect(find.text('Karrada, Baghdad'), findsOneWidget);
    expect(find.text('Discover on Wensa'), findsOneWidget);
    expect(find.text('WENSA'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the smoke test**

Run: `flutter test test/core/share/content_share_card_test.dart`
Expected: PASS (the null `coverBytes` path renders the gradient fallback, no asset load needed).

- [ ] **Step 4: Commit**

```bash
git add lib/core/share/content_share_card.dart test/core/share/content_share_card_test.dart
git commit -m "feat(share): add ContentShareCard for place/event images"
```

---

## Task 6: Extract reusable TicketCard + ShareableTicketCard

**Files:**
- Create: `lib/features/bookings_history/presentation/widgets/ticket_card.dart`
- Modify: `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart`

This moves the existing private ticket visual into a public, reusable widget so the on-screen ticket and the shared image are identical.

- [ ] **Step 1: Create `ticket_card.dart` with the extracted visual**

```dart
// lib/features/bookings_history/presentation/widgets/ticket_card.dart
//
// Reusable ticket visual (info section, tear line, QR), used both on the ticket
// detail screen and inside the shareable ticket image.
import 'package:flutter/material.dart';
import 'package:future_riverpod/core/share/branded_header.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/qr_block.dart';

const double _kTopHeight = 270.0;
const double _kTearHalf = 14.0;
const double _kNotchRadius = 14.0;

class TicketInfoCell {
  const TicketInfoCell({required this.label, required this.value});
  final String label;
  final String value;
}

/// The ticket card visual. Stateful only to measure the top section so the
/// tear-line notch lines up at the right Y.
class TicketCard extends StatefulWidget {
  const TicketCard({
    super.key,
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
    this.waylCode,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<TicketInfoCell> cells;
  final String? waylCode;

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  final _topKey = GlobalKey();
  double _tearLineY = _kTopHeight + _kTearHalf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTearLine());
  }

  void _updateTearLine() {
    final ctx = _topKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final actual = box.size.height + _kTearHalf;
    if ((actual - _tearLineY).abs() > 0.5) {
      setState(() => _tearLineY = actual);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surfaceContainer;
    final tearLineY = _tearLineY;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipPath(
        clipper: _TicketClipper(tearLineY),
        child: Container(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                key: _topKey,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    widget.statusBadge,
                    const SizedBox(height: 20),
                    _InfoGrid(cells: widget.cells),
                    if (widget.waylCode != null &&
                        widget.waylCode!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _CodePill(
                        code: widget.waylCode!,
                        isArabic: widget.isArabic,
                      ),
                    ],
                  ],
                ),
              ),
              _TearLine(color: cs.onSurface.withValues(alpha: 0.18)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Text(
                      widget.isArabic ? 'امسح رمز QR' : 'Scan This QR',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isArabic
                          ? 'وجّه الكاميرا إلى مكان المسح'
                          : 'Point This QR To The Scan Place',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: widget.qrToken.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: QrBlock(qrToken: widget.qrToken),
                            )
                          : SizedBox(
                              width: 232,
                              height: 232,
                              child: Icon(
                                Icons.qr_code_rounded,
                                size: 120,
                                color: cs.onSurface.withValues(alpha: 0.15),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded, fixed-width composition for the shared ticket image.
class ShareableTicketCard extends StatelessWidget {
  const ShareableTicketCard({
    super.key,
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
    this.waylCode,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<TicketInfoCell> cells;
  final String? waylCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 360,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandedHeader(),
          const SizedBox(height: 16),
          TicketCard(
            qrToken: qrToken,
            displayName: displayName,
            isArabic: isArabic,
            statusBadge: statusBadge,
            cells: cells,
            waylCode: waylCode,
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.cells});
  final List<TicketInfoCell> cells;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final rows = <List<TicketInfoCell>>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add([cells[i], if (i + 1 < cells.length) cells[i + 1]]);
    }

    return Column(
      children: List.generate(rows.length, (ri) {
        final row = rows[ri];
        return Column(
          children: [
            if (ri > 0)
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: row.map((cell) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.label,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cell.value,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code, required this.isArabic});
  final String code;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.onSurface.withValues(alpha: 0.18);
    final labelColor = cs.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isArabic ? 'الرمز' : 'Code',
            style: tt.labelMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            code,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TearLine extends StatelessWidget {
  const _TearLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kTearHalf * 2,
      child: CustomPaint(
        painter: _DashPainter(color: color),
        size: const Size(double.infinity, _kTearHalf * 2),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 9.0;
    const gapWidth = 7.0;
    final y = size.height / 2;
    double x = 4.0;
    while (x < size.width - 4) {
      final end = (x + dashWidth).clamp(0.0, size.width - 4.0);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(this.tearLineY);
  final double tearLineY;

  @override
  Path getClip(Size size) {
    const r = 24.0;
    const nr = _kNotchRadius;
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r), clockwise: true)
      ..lineTo(w, tearLineY - nr)
      ..arcToPoint(
        Offset(w, tearLineY + nr),
        radius: const Radius.circular(nr),
        clockwise: false,
      )
      ..lineTo(w, h - r)
      ..arcToPoint(
        Offset(w - r, h),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(r, h)
      ..arcToPoint(
        Offset(0, h - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(0, tearLineY + nr)
      ..arcToPoint(
        Offset(0, tearLineY - nr),
        radius: const Radius.circular(nr),
        clockwise: false,
      )
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r), clockwise: true)
      ..close();
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.tearLineY != tearLineY;
}
```

> Note: the original `_CodePill` had an inline copy button; the shared card is a static image, so the copy button is intentionally dropped from the reusable card (copy-to-clipboard remains available elsewhere if needed). The pill keeps the same look (label + code).

- [ ] **Step 2: Rewrite the page body to use `TicketCard` + add the Share button**

In `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart`:

a) Replace the imports block at the top (lines 1-17) — remove `flutter/services.dart` usage that was only for the copy button if now unused (keep it; Clipboard may be unused now — remove if `flutter analyze` flags it), and add the new imports:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:future_riverpod/core/share/share_service.dart';
import 'package:future_riverpod/core/share/share_link.dart';
import 'package:future_riverpod/features/booking/domain/models/booking.dart';
import 'package:future_riverpod/features/booking/domain/models/booking_enums.dart';
import 'package:future_riverpod/features/booking/domain/models/membership.dart';
import 'package:future_riverpod/features/booking/presentation/providers/availability_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/providers/tickets_provider.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_card.dart';
import 'package:future_riverpod/features/bookings_history/presentation/widgets/ticket_status_badge.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
```

b) Delete the now-extracted code from this file: the layout constants `_kTopHeight`/`_kTearHalf`/`_kNotchRadius`, and the classes `_TicketBody`, `_TicketBodyState`, `_TearLine`, `_DashPainter`, `_TicketClipper`, `_InfoCell`, `_InfoGrid`, `_CodePill`, `_CopyButton`. (They now live in `ticket_card.dart`, with `_InfoCell` renamed to `TicketInfoCell`.)

c) In `_BookingDetailBody.build`, change the cell type and the return. Replace every `_InfoCell(` with `TicketInfoCell(` (the `extraCells`, `cells` lists). Change the final return from `_TicketBody(...)` to:

```dart
    return _TicketScreen(
      qrToken: booking.qrToken,
      displayName: name,
      isArabic: isArabic,
      buildStatusBadge: () => TicketStatusBadge.booking(
        status: booking.status,
        isArabic: isArabic,
      ),
      cells: cells,
      waylCode: booking.waylCode,
    );
```

d) In `_MembershipDetailBody.build`, change `_InfoCell(` → `TicketInfoCell(` in the `cells` list and change the return from `_TicketBody(...)` to:

```dart
    return _TicketScreen(
      qrToken: membership.qrToken,
      displayName: displayName,
      isArabic: isArabic,
      buildStatusBadge: () => TicketStatusBadge.membership(
        status: membership.status,
        isArabic: isArabic,
      ),
      cells: cells,
      waylCode: membership.waylCode,
    );
```

e) Add the new `_TicketScreen` widget (on-screen ticket + Share button + busy state). Insert where `_TicketBody` used to be:

```dart
// ─────────────────────────────────────────────────────────────────────────────
//  On-screen ticket: the card + a "Share Ticket" button
// ─────────────────────────────────────────────────────────────────────────────

class _TicketScreen extends StatefulWidget {
  const _TicketScreen({
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.buildStatusBadge,
    required this.cells,
    this.waylCode,
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget Function() buildStatusBadge;
  final List<TicketInfoCell> cells;
  final String? waylCode;

  @override
  State<_TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<_TicketScreen> {
  final ShareService _share = ShareService();
  bool _sharing = false;

  Future<void> _onShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await _share.renderToPng(
        context,
        ShareableTicketCard(
          qrToken: widget.qrToken,
          displayName: widget.displayName,
          isArabic: widget.isArabic,
          statusBadge: widget.buildStatusBadge(),
          cells: widget.cells,
          waylCode: widget.waylCode,
        ),
        isAr: widget.isArabic,
        delay: const Duration(milliseconds: 300),
      );
      if (!mounted) return;
      await _share.shareImage(
        context,
        png,
        caption: ticketShareCaption(
          name: widget.displayName,
          isAr: widget.isArabic,
        ),
        fileName: 'wensa_ticket.png',
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic ? 'تعذّرت المشاركة' : 'Couldn\'t share',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        children: [
          TicketCard(
            qrToken: widget.qrToken,
            displayName: widget.displayName,
            isArabic: widget.isArabic,
            statusBadge: widget.buildStatusBadge(),
            cells: widget.cells,
            waylCode: widget.waylCode,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sharing ? null : _onShare,
              icon: _sharing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(CupertinoIcons.share, size: 20),
              label: Text(
                _sharing
                    ? (widget.isArabic ? 'جارٍ التحضير…' : 'Preparing…')
                    : (widget.isArabic ? 'مشاركة التذكرة' : 'Share Ticket'),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify analyze + tests pass**

Run: `flutter analyze && flutter test`
Expected: No analyzer issues (remove any now-unused imports it flags, e.g. `flutter/services.dart` if Clipboard is gone). Existing + new tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/bookings_history/presentation/widgets/ticket_card.dart lib/features/bookings_history/presentation/pages/ticket_detail_page.dart
git commit -m "feat(ticket): reusable TicketCard + Share Ticket button with image export"
```

---

## Task 7: Repository `recordShare` + event migration

**Files:**
- Modify: `lib/features/places/domain/repositories/place_details_repository.dart:50` (after `recordView`)
- Modify: `lib/features/events/domain/repositories/events_repository.dart` (after its `recordView`)
- Create: `supabase/migrations/20260529000000_increment_event_share_count.sql`

- [ ] **Step 1: Add `recordShare` to the place repository**

In `place_details_repository.dart`, add this method inside the `PlaceDetailsRepository` class, right after `recordView`:

```dart
  /// Atomically increments places.shares_count (best-effort analytics).
  Future<void> recordShare(String placeId) async {
    await _client.rpc('increment_share_count', params: {'p_id': placeId});
  }
```

- [ ] **Step 2: Add `recordShare` to the events repository**

First confirm the class/field name:
Run: `grep -n "class EventsRepository\|final.*_client\|recordView" lib/features/events/domain/repositories/events_repository.dart`
Then add, inside `EventsRepository`, right after `recordView` (use the same client field name the file uses, typically `_client`):

```dart
  /// Atomically increments events.shares_count (best-effort analytics).
  Future<void> recordShare(String eventId) async {
    await _client.rpc('increment_event_share_count', params: {'p_id': eventId});
  }
```

- [ ] **Step 3: Create the event share-count migration**

```sql
-- supabase/migrations/20260529000000_increment_event_share_count.sql
--
-- Adds an RPC to atomically increment events.shares_count, mirroring the
-- existing public.increment_share_count(uuid) for places.

CREATE OR REPLACE FUNCTION public.increment_event_share_count(p_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = content, public
AS $$
  UPDATE content.events SET shares_count = shares_count + 1 WHERE id = p_id;
$$;

GRANT EXECUTE ON FUNCTION public.increment_event_share_count(uuid) TO authenticated;

-- Ensure the existing places function is callable by the app, too.
GRANT EXECUTE ON FUNCTION public.increment_share_count(uuid) TO authenticated;
```

- [ ] **Step 4: Verify analyze**

Run: `flutter analyze lib/features/places/domain/repositories/place_details_repository.dart lib/features/events/domain/repositories/events_repository.dart`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/places/domain/repositories/place_details_repository.dart lib/features/events/domain/repositories/events_repository.dart supabase/migrations/20260529000000_increment_event_share_count.sql
git commit -m "feat(share): recordShare repo methods + event share-count RPC"
```

> **Apply the migration yourself** via your Supabase flow (e.g. `supabase db push`) — it is not run automatically. Until applied, event sharing still works; only the event share-count increment will error and is silently ignored.

---

## Task 8: Wire share button into the Place details page

**Files:**
- Modify: `lib/features/places/presentation/pages/place_details_page.dart`

- [ ] **Step 1: Add imports**

Add to the import block:
```dart
import 'package:future_riverpod/core/share/content_share_card.dart';
import 'package:future_riverpod/core/share/share_link.dart';
import 'package:future_riverpod/core/share/share_service.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/domain/repositories/place_details_repository.dart';
import 'package:share_plus/share_plus.dart';
```

- [ ] **Step 2: Add share state fields**

In `_PlaceDetailsPageState`, after `late final ScrollController _scrollCtrl;`:
```dart
  final ShareService _share = ShareService();
  bool _sharing = false;
```

- [ ] **Step 3: Add the share handler**

Add this method to `_PlaceDetailsPageState`:
```dart
  Future<void> _onShare(PlaceModel place) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = _isAr
          ? (place.nameAr.isNotEmpty ? place.nameAr : place.nameEn)
          : (place.nameEn.isNotEmpty ? place.nameEn : place.nameAr);
      final sep = _isAr ? '، ' : ', ';
      final subtitle = [place.area, place.city]
          .where((e) => e != null && e.isNotEmpty)
          .join(sep);
      final cover = place.coverImageUrl;
      final coverBytes = (cover != null && cover.isNotEmpty)
          ? await _share.fetchImageBytes(cover)
          : null;
      if (!mounted) return;
      final png = await _share.renderToPng(
        context,
        ContentShareCard(
          name: name,
          subtitle: subtitle,
          coverBytes: coverBytes,
          isAr: _isAr,
          footerText: _isAr ? 'اكتشفه على ونسة' : 'Discover on Wensa',
        ),
        isAr: _isAr,
      );
      if (!mounted) return;
      final result = await _share.shareImage(
        context,
        png,
        caption: placeShareCaption(name: name, id: place.id, isAr: _isAr),
        fileName: 'wensa_place.png',
      );
      if (result.status != ShareResultStatus.dismissed) {
        ref.read(placeDetailsRepositoryProvider).recordShare(place.id).ignore();
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'تعذّرت المشاركة' : 'Couldn\'t share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
```

- [ ] **Step 4: Add the share button to the SliverAppBar `actions`**

In the `actions: [ ... ]` list, insert this **before** the existing favourite `Padding(...)`:
```dart
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: PlaceAppBarButton(
                        icon: Icon(
                          CupertinoIcons.share,
                          color: collapsed ? cs.onSurface : AppColors.white,
                        ),
                        onTap: () => _onShare(place),
                        collapsed: collapsed,
                        sfSymbol: 'square.and.arrow.up',
                      ),
                    ),
```

- [ ] **Step 5: Verify analyze**

Run: `flutter analyze lib/features/places/presentation/pages/place_details_page.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/places/presentation/pages/place_details_page.dart
git commit -m "feat(places): add share button with branded image + analytics"
```

---

## Task 9: Wire share button into the Event details page

**Files:**
- Modify: `lib/features/events/presentation/pages/event_details_page.dart`

- [ ] **Step 1: Add imports**

```dart
import 'package:future_riverpod/core/share/content_share_card.dart';
import 'package:future_riverpod/core/share/share_link.dart';
import 'package:future_riverpod/core/share/share_service.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/events/domain/repositories/events_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
```

- [ ] **Step 2: Add share state fields**

In `_EventDetailsPageState`, after `late final ScrollController _scrollCtrl;`:
```dart
  final ShareService _share = ShareService();
  bool _sharing = false;

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
```

- [ ] **Step 3: Add the share handler**

```dart
  Future<void> _onShare(EventModel event) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = _isAr
          ? (event.titleAr.isNotEmpty ? event.titleAr : event.titleEn)
          : (event.titleEn.isNotEmpty ? event.titleEn : event.titleAr);
      final subtitle = _fmtDate(event.startDate);
      final cover = event.coverImageUrl;
      final coverBytes = (cover != null && cover.isNotEmpty)
          ? await _share.fetchImageBytes(cover)
          : null;
      if (!mounted) return;
      final png = await _share.renderToPng(
        context,
        ContentShareCard(
          name: name,
          subtitle: subtitle,
          coverBytes: coverBytes,
          isAr: _isAr,
          footerText: _isAr ? 'اكتشفه على ونسة' : 'Discover on Wensa',
        ),
        isAr: _isAr,
      );
      if (!mounted) return;
      final result = await _share.shareImage(
        context,
        png,
        caption: eventShareCaption(name: name, id: event.id, isAr: _isAr),
        fileName: 'wensa_event.png',
      );
      if (result.status != ShareResultStatus.dismissed) {
        ref.read(eventsRepositoryProvider).recordShare(event.id).ignore();
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'تعذّرت المشاركة' : 'Couldn\'t share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
```

- [ ] **Step 4: Add the share button to the SliverAppBar `actions`**

Insert **before** the favourite button `Padding(...)`:
```dart
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: PlaceAppBarButton(
                        icon: Icon(
                          CupertinoIcons.share,
                          color: collapsed ? cs.onSurface : AppColors.white,
                        ),
                        onTap: () => _onShare(event),
                        collapsed: collapsed,
                        sfSymbol: 'square.and.arrow.up',
                      ),
                    ),
```

- [ ] **Step 5: Verify analyze**

Run: `flutter analyze lib/features/events/presentation/pages/event_details_page.dart`
Expected: No issues. (Confirm `eventsRepositoryProvider` is the correct provider name from Step 2 of Task 7; adjust import/usage if different.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/events/presentation/pages/event_details_page.dart
git commit -m "feat(events): add share button with branded image + analytics"
```

---

## Task 10: Full analyze + test gate

**Files:** none (verification)

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues. Fix any unused-import warnings (notably leftover `flutter/services.dart`/`Clipboard` in `ticket_detail_page.dart`).

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All PASS.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "chore: analyze/test cleanup for share feature"
```

(Skip if nothing changed.)

---

## Task 11: Manual verification (device/simulator)

**Files:** none (manual)

The render + native share + QR can only be verified by running the app.

- [ ] **Step 1: Launch**

Run: `flutter run` (iOS simulator or Android emulator).

- [ ] **Step 2: Place share**

Open a place → tap the share icon (top bar). Expect: a brief "Preparing…"/spinner, then the OS share sheet with a branded card image (cover, name, city) and a caption containing `https://wensa.app/place?placeId=...`. Verify in both English and Arabic (toggle locale) — including RTL layout and the gradient fallback when a place has no cover.

- [ ] **Step 3: Event share**

Open an event → share. Expect a branded card with the event date as subtitle + event caption/link.

- [ ] **Step 4: Ticket share**

Open a booking and a membership ticket → tap "Share Ticket". Expect a branded ticket image with issuer/venue name, status, all detail cells, the wayl code pill, and a **scannable** QR. Scan the shared image's QR to confirm it resolves the same as the on-screen QR.

- [ ] **Step 5: Analytics**

After sharing a place and an event (and applying the migration), confirm `shares_count` incremented on the respective rows (Supabase dashboard / SQL). Dismissing the share sheet should NOT increment (iOS; on Android dismissal detection is unreliable and may still count — acceptable).

- [ ] **Step 6: Final commit (if any tweaks)**

```bash
git add -A
git commit -m "fix(share): manual-QA tweaks"
```

---

## Self-Review Notes (author)

- **Spec coverage:** share buttons on place/event/ticket ✓ (Tasks 8/9/6); branded image with app icon + WENSA ✓ (Task 4); ticket image with issuer name + all details + live QR ✓ (Task 6); caption + placeholder link ✓ (Task 2); `shares_count` analytics ✓ (Task 7); localization/RTL ✓ (handled in each card/handler); error handling + fallback ✓ (ShareService + handlers).
- **Type consistency:** `TicketInfoCell`, `TicketCard`, `ShareableTicketCard`, `ContentShareCard`, `BrandedHeader`, `ShareService.{renderToPng,shareImage,shareText,fetchImageBytes}`, `recordShare` used identically across tasks.
- **Known risk:** ticket tear-line uses post-frame measurement; the 300ms capture delay mitigates a mis-aligned notch in the exported image — verify in Task 11. If the notch is off in the image, increase the delay or pass a precomputed `tearLineY` to `TicketCard`.
- **Verify during execution:** exact `EventsRepository` client field/provider names (Task 7 Step 2 / Task 9 Step 5); that `flutter pub add` resolved `SharePlus.instance` API (v9+); remove any unused imports surfaced by `flutter analyze`.

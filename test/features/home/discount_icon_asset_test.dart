import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression guard: the Discounts category icon must be a plain Lottie
  // animation JSON. It was originally shipped as a dotLottie (.lottie) ZIP
  // whose first inner file is `manifest.json` (NOT an animation); the lottie
  // package picked that manifest and threw a parse error at runtime.
  test('discount category icon is a valid Lottie animation json', () {
    final file = File('assets/lottie/categories/discount.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'assets/lottie/categories/discount.json must exist',
    );

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    // Lottie animations have these top-level keys. A dotLottie manifest does
    // not (it has {animations, generator, version:"1.0"}), so these assertions
    // fail loudly if someone swaps a manifest/dotLottie back in.
    expect(data.containsKey('v'), isTrue, reason: 'missing Lottie version "v"');
    expect(data.containsKey('fr'), isTrue, reason: 'missing frame rate "fr"');
    expect(data.containsKey('op'), isTrue, reason: 'missing out point "op"');
    expect(data['layers'], isA<List>(), reason: '"layers" must be a list');
  });
}

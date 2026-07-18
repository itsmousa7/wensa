import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/hyperpay_payment.dart';

void main() {
  group('detectBrand', () {
    test(
      '4-prefix is VISA',
      () => expect(detectBrand('4111111111111111'), 'VISA'),
    );
    test(
      '5-prefix is MASTER',
      () => expect(detectBrand('5454545454545454'), 'MASTER'),
    );
    test(
      '2-series Mastercard is MASTER',
      () => expect(detectBrand('2221000000000009'), 'MASTER'),
    );
    test(
      'other prefixes are null',
      () => expect(detectBrand('371449635398431'), null),
    );
    test('empty is null', () => expect(detectBrand(''), null));
  });

  group('luhnCheck', () {
    test(
      'valid VISA test number passes',
      () => expect(luhnCheck('4111111111111111'), true),
    );
    test(
      'invalid number fails',
      () => expect(luhnCheck('4111111111111112'), false),
    );
    test('non-digits fail', () => expect(luhnCheck('4111abc111111111'), false));
    test('too short fails', () => expect(luhnCheck('411'), false));
  });

  group('isValidExpiry', () {
    test('month 13 invalid', () => expect(isValidExpiry('13', '39'), false));
    test('month 00 invalid', () => expect(isValidExpiry('00', '39'), false));
    test(
      'far-future year valid',
      () => expect(isValidExpiry('12', '39'), true),
    );
    test('past year invalid', () => expect(isValidExpiry('12', '20'), false));
  });

  group('normalizeYear', () {
    test('2-digit gets 20 prefix', () => expect(normalizeYear('39'), '2039'));
    test('4-digit unchanged', () => expect(normalizeYear('2039'), '2039'));
  });

  group('isValidCvv', () {
    test('3 digits valid', () => expect(isValidCvv('123'), true));
    test('2 digits invalid', () => expect(isValidCvv('12'), false));
    test('letters invalid', () => expect(isValidCvv('12a'), false));
  });
}

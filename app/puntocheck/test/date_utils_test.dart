import 'package:flutter_test/flutter_test.dart';
import 'package:puntocheck/utils/date_utils.dart' as date_utils;

void main() {
  group('daysRemainingInclusive', () {
    test('counts same-day expiration as zero even if hours remain', () {
      final now = DateTime.utc(2024, 1, 10, 10);
      final end = DateTime.utc(2024, 1, 10, 23, 59);

      expect(date_utils.daysRemainingInclusive(now, end), 0);
    });

    test('counts next-day early expiration as one day', () {
      final now = DateTime.utc(2024, 1, 10, 23);
      final end = DateTime.utc(2024, 1, 11, 5);

      expect(date_utils.daysRemainingInclusive(now, end), 1);
    });
  });

  group('isExpired', () {
    test('considers past time on same day as expired', () {
      final now = DateTime.utc(2024, 1, 10, 12);
      final end = DateTime.utc(2024, 1, 10, 11);

      expect(date_utils.isExpired(now, end), isTrue);
    });
  });

  group('humanRemainingText', () {
    test('returns vence hoy for same-day active subscription', () {
      final now = DateTime.utc(2024, 1, 10, 10);
      final end = DateTime.utc(2024, 1, 10, 23, 59);

      expect(date_utils.humanRemainingText(now, end), 'Vence hoy');
    });

    test('returns vence en 1 dia when next day', () {
      final now = DateTime.utc(2024, 1, 10, 12);
      final end = DateTime.utc(2024, 1, 11, 9);

      expect(date_utils.humanRemainingText(now, end), 'Vence en 1 dia');
    });

    test('returns vencio today when already expired same day', () {
      final now = DateTime.utc(2024, 1, 10, 12);
      final end = DateTime.utc(2024, 1, 10, 8);

      expect(date_utils.humanRemainingText(now, end), 'Vencio hoy');
    });

    test('returns vencio hace N dias for overdue subscriptions', () {
      final now = DateTime.utc(2024, 1, 12, 12);
      final end = DateTime.utc(2024, 1, 10, 8);

      expect(date_utils.humanRemainingText(now, end), 'Vencio hace 2 dias');
    });
  });
}

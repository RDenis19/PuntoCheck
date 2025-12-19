import 'package:flutter_test/flutter_test.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/subscription_state.dart';

void main() {
  group('SubscriptionState.compute', () {
    test('flags expired when end date is in the past', () {
      final now = DateTime.utc(2024, 1, 10, 10);
      final end = DateTime.utc(2024, 1, 9, 23);

      final state = SubscriptionState.compute(now: now, endDate: end);

      expect(state.status, SubscriptionStatus.expired);
      expect(state.shouldShowBanner, isTrue);
    });

    test('expires today when still active but same calendar day', () {
      final now = DateTime.utc(2024, 1, 10, 9);
      final end = DateTime.utc(2024, 1, 10, 22);

      final state = SubscriptionState.compute(now: now, endDate: end);

      expect(state.status, SubscriptionStatus.expiresToday);
      expect(state.daysRemaining, 0);
    });

    test('expiring in 7 days bucket', () {
      final now = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 1, 4);

      final state = SubscriptionState.compute(now: now, endDate: end);

      expect(state.status, SubscriptionStatus.expiringIn7Days);
    });

    test('expiring in 15 days bucket', () {
      final now = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 1, 12);

      final state = SubscriptionState.compute(now: now, endDate: end);

      expect(state.status, SubscriptionStatus.expiringIn15Days);
    });

    test('active when beyond 15 days', () {
      final now = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 2, 1);

      final state = SubscriptionState.compute(now: now, endDate: end);

      expect(state.status, SubscriptionStatus.active);
      expect(state.shouldShowBanner, isFalse);
    });

    test('forces expired when backend status is vencido', () {
      final now = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 2, 1);

      final state = SubscriptionState.compute(
        now: now,
        endDate: end,
        backendStatus: EstadoSuscripcion.vencido,
      );

      expect(state.status, SubscriptionStatus.expired);
    });
  });
}

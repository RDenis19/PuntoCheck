import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/utils/date_utils.dart' as date_utils;

enum SubscriptionStatus {
  expired,
  expiresToday,
  expiringIn7Days,
  expiringIn15Days,
  active,
}

class SubscriptionState {
  final SubscriptionStatus status;
  final int daysRemaining;
  final DateTime endDate;
  final EstadoSuscripcion? backendStatus;

  const SubscriptionState({
    required this.status,
    required this.daysRemaining,
    required this.endDate,
    this.backendStatus,
  });

  bool get isExpired => status == SubscriptionStatus.expired;
  bool get shouldShowBanner => status != SubscriptionStatus.active;

  factory SubscriptionState.compute({
    required DateTime now,
    required DateTime endDate,
    EstadoSuscripcion? backendStatus,
  }) {
    final remaining = date_utils.daysRemainingInclusive(now, endDate);
    final expiredFlag =
        date_utils.isExpired(now, endDate) ||
        backendStatus == EstadoSuscripcion.vencido ||
        backendStatus == EstadoSuscripcion.cancelado;

    if (expiredFlag) {
      return SubscriptionState(
        status: SubscriptionStatus.expired,
        daysRemaining: remaining,
        endDate: endDate,
        backendStatus: backendStatus,
      );
    }

    if (remaining <= 0) {
      return SubscriptionState(
        status: SubscriptionStatus.expiresToday,
        daysRemaining: remaining,
        endDate: endDate,
        backendStatus: backendStatus,
      );
    }

    if (remaining <= 7) {
      return SubscriptionState(
        status: SubscriptionStatus.expiringIn7Days,
        daysRemaining: remaining,
        endDate: endDate,
        backendStatus: backendStatus,
      );
    }

    if (remaining <= 15) {
      return SubscriptionState(
        status: SubscriptionStatus.expiringIn15Days,
        daysRemaining: remaining,
        endDate: endDate,
        backendStatus: backendStatus,
      );
    }

    return SubscriptionState(
      status: SubscriptionStatus.active,
      daysRemaining: remaining,
      endDate: endDate,
      backendStatus: backendStatus,
    );
  }
}

import 'package:flutter/material.dart';

/// Calcula la cantidad de d\u00edas restantes tomando solo la fecha
/// (ignora horas/minutos) para evitar valores 0 cuando faltan <24h.
int daysRemainingInclusive(DateTime now, DateTime endDate) {
  final today = DateUtils.dateOnly(now);
  final endDay = DateUtils.dateOnly(endDate);
  return endDay.difference(today).inDays;
}

/// Indica si la fecha de fin ya pas\u00f3 (considera horas/minutos).
bool isExpired(DateTime now, DateTime endDate) {
  return endDate.isBefore(now);
}

/// Mensaje legible sobre tiempo restante o vencido.
String humanRemainingText(DateTime now, DateTime endDate) {
  if (isExpired(now, endDate)) {
    final overdueDays = DateUtils.dateOnly(
      now,
    ).difference(DateUtils.dateOnly(endDate)).inDays;
    if (overdueDays <= 0) return 'Vencio hoy';
    if (overdueDays == 1) return 'Vencio hace 1 dia';
    return 'Vencio hace $overdueDays dias';
  }

  final remaining = daysRemainingInclusive(now, endDate);
  if (remaining <= 0) return 'Vence hoy';
  if (remaining == 1) return 'Vence en 1 dia';
  return 'Vence en $remaining dias';
}

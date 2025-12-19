import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAlertConstants {
  AuditorAlertConstants._();

  static const statuses = <String>['pendiente', 'en_revision', 'cerrada'];

  static Color severityColor(GravedadAlerta? s) {
    switch (s?.value) {
      case 'grave_legal':
        return AppColors.errorRed;
      case 'moderada':
        return AppColors.warningOrange;
      case 'leve':
      default:
        return AppColors.infoBlue;
    }
  }

  static Color statusColor(String? status) {
    switch ((status ?? '').trim()) {
      case 'pendiente':
        return AppColors.warningOrange;
      case 'en_revision':
        return AppColors.infoBlue;
      case 'cerrada':
        return AppColors.successGreen;
      default:
        return AppColors.neutral600;
    }
  }

  static String statusLabel(String? status) {
    switch ((status ?? '').trim()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'cerrada':
        return 'Cerrada';
      default:
        return (status ?? '—').toString();
    }
  }
}

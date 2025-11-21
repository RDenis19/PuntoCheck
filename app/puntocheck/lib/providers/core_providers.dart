import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/organization_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../services/biometric_service.dart';

// Instancias de Servicios (Singleton-ish via Provider)

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

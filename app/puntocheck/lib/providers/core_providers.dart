import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/compliance_service.dart';
import '../services/manager_service.dart';
import '../services/operations_service.dart';
import '../services/organization_service.dart';
import '../services/payments_service.dart';
import '../services/staff_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../services/super_admin_service.dart';

// ============================================================================
// Servicios centrales (inyeccion de dependencias)
// ============================================================================
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService.instance;
});

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  return PaymentsService.instance;
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService.instance;
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService.instance;
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService.instance;
});

final complianceServiceProvider = Provider<ComplianceService>((ref) {
  return ComplianceService.instance;
});

final operationsServiceProvider = Provider<OperationsService>((ref) {
  return OperationsService.instance;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService.instance;
});

final managerServiceProvider = Provider((ref) {
  return ManagerService.instance;
});

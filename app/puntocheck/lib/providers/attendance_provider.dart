import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_shift_model.dart';
import '../models/geo_location.dart';
import 'core_providers.dart';
import 'auth_provider.dart';
import 'package:state_notifier/state_notifier.dart';

// --- Providers de Lectura ---

/// Historial de asistencia del usuario
final attendanceHistoryProvider = FutureProvider.autoDispose<List<WorkShift>>((ref) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getMyHistory();
});

/// Turno activo actual (si existe)
final activeShiftProvider = FutureProvider.autoDispose<WorkShift?>((ref) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getActiveShift();
});

/// Estadísticas de hoy
final todayStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getTodayStats();
});

// --- Controller ---

class AttendanceController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AttendanceController(this._ref) : super(const AsyncValue.data(null));

  Future<void> checkIn({
    required GeoLocation location,
    required File photoFile,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuario no autenticado');

      final profile = await _ref.read(currentUserProfileProvider.future);
      if (profile == null) throw Exception('Perfil no cargado');
      
      if (profile.organizationId == null) throw Exception('Usuario no pertenece a una organización');

      // 1. Subir foto
      final storage = _ref.read(storageServiceProvider);
      final photoPath = await storage.uploadEvidence(
        photoFile, 
        user.id, 
        profile.organizationId!
      );

      // 2. Registrar asistencia
      final service = _ref.read(attendanceServiceProvider);
      await service.checkIn(
        location: location,
        photoPath: photoPath,
        address: address,
      );
      
      // Invalidar providers para refrescar la UI
      _ref.invalidate(activeShiftProvider);
      _ref.invalidate(attendanceHistoryProvider);
      _ref.invalidate(todayStatsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkOut({
    required String shiftId,
    required GeoLocation location,
    File? photoFile,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? photoPath;
      
      if (photoFile != null) {
        final user = _ref.read(currentUserProvider);
        final profile = await _ref.read(currentUserProfileProvider.future);
        
        if (user != null && profile != null && profile.organizationId != null) {
           final storage = _ref.read(storageServiceProvider);
           photoPath = await storage.uploadEvidence(
             photoFile, 
             user.id, 
             profile.organizationId!
           );
        }
      }

      final service = _ref.read(attendanceServiceProvider);
      await service.checkOut(
        shiftId: shiftId,
        location: location,
        photoPath: photoPath,
        address: address,
      );

      // Invalidar providers
      _ref.invalidate(activeShiftProvider);
      _ref.invalidate(attendanceHistoryProvider);
      _ref.invalidate(todayStatsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final attendanceControllerProvider = StateNotifierProvider<AttendanceController, AsyncValue<void>>((ref) {
  return AttendanceController(ref);
});

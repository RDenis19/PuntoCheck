import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/work_schedule_model.dart';
import 'core_providers.dart';

/// Horario semanal del usuario
final myScheduleProvider = FutureProvider<List<WorkSchedule>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  return await service.getMySchedule();
});

// --- Controller (Admin) ---

class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ScheduleController(this._ref) : super(const AsyncValue.data(null));

  /// ADMIN: Crea/asigna un horario a un empleado
  Future<void> createSchedule(WorkSchedule schedule) async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(scheduleServiceProvider);
      await service.createSchedule(schedule);
      
      // Invalidar el provider de horarios para refrescar los datos
      _ref.invalidate(myScheduleProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final scheduleControllerProvider = StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
  return ScheduleController(ref);
});

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/global_settings.dart';

/// Servicio para manejar configuraciones globales (fila unica en `global_settings`).
class GlobalSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'global_settings';
  static const String _rowId = 'default';

  /// Obtiene la configuracion global. Crea una fila por defecto si no existe.
  Future<GlobalSettings> getSettings() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', _rowId)
          .maybeSingle();

      if (response != null) {
        return GlobalSettings.fromJson(response);
      }

      final defaults = GlobalSettings.defaults();
      await _supabase.from(_table).upsert(defaults.toJson());
      return defaults;
    } catch (e) {
      throw Exception('Error obteniendo configuracion global: $e');
    }
  }

  /// Guarda la configuracion global (upsert de la fila unica).
  Future<GlobalSettings> updateSettings(GlobalSettings settings) async {
    try {
      final payload = settings.copyWith(id: _rowId).toJson();
      final data = await _supabase
          .from(_table)
          .upsert(payload)
          .select()
          .single();
      return GlobalSettings.fromJson(data);
    } catch (e) {
      throw Exception('Error guardando configuracion global: $e');
    }
  }
}

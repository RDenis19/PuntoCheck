import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar configuraciones globales (fila unica en `global_settings`).
class GlobalSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'global_settings';
  static const String _rowId = 'default';

  /// Obtiene la configuracion global. Crea una fila por defecto si no existe.
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', _rowId)
          .maybeSingle();

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }

      // Si no hay fila, creamos una por defecto.
      final defaults = _defaultSettings();
      await _supabase.from(_table).upsert(defaults);
      return defaults;
    } catch (e) {
      throw Exception('Error obteniendo configuración global: $e');
    }
  }

  /// Actualiza parcial o totalmente la configuracion global.
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      final payload = <String, dynamic>{'id': _rowId, ...updates};
      await _supabase.from(_table).upsert(payload);
    } catch (e) {
      throw Exception('Error guardando configuración global: $e');
    }
  }

  Map<String, dynamic> _defaultSettings() => {
        'id': _rowId,
        'tolerance_minutes': 5,
        'geofence_radius': 50,
        'require_photo': true,
        'sender_email': '',
        'alert_threshold': 3,
        'admin_auto_domain': '',
        'trial_max_orgs': 0,
        'trial_days': 14,
      };
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/models/perfil_model.dart';
import 'package:puntocheck/models/solicitud_permiso_model.dart';
import 'package:puntocheck/models/enums.dart';

class ManagementService {
  final SupabaseClient _supabase;

  ManagementService(this._supabase);

  // --- GESTIÓN DE PERSONAL ---

  /// Obtiene la lista de empleados de la organización.
  /// RLS filtra automáticamente para mostrar solo los de la misma Org.
  Future<List<PerfilModel>> getEmpleadosOrganizacion() async {
    try {
      return await _supabase
          .from('perfiles')
          .select()
          .eq('activo', true) // Solo activos
          .order('apellidos', ascending: true)
          .withConverter<List<PerfilModel>>(
            (data) => data.map((e) => PerfilModel.fromJson(e)).toList(),
          );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando empleados: ${e.message}');
    }
  }

  // --- GESTIÓN DE PERMISOS ---

  /// Crea una solicitud de permiso (Empleado).
  Future<void> solicitarPermiso(SolicitudPermisoModel solicitud) async {
    try {
      await _supabase.from('solicitudes_permisos').insert({
        'solicitante_id': _supabase.auth.currentUser!.id,
        'organizacion_id': (await _getOrgIdUsuarioActual()), // Helper privado
        ...solicitud.toJsonCreacion(), // Usamos el método específico del modelo
        'estado': EstadoAprobacion.pendiente.name,
      });
    } on PostgrestException catch (e) {
      throw Exception('Error creando solicitud: ${e.message}');
    }
  }

  /// Aprueba o Rechaza un permiso (Manager/Admin).
  Future<void> resolverPermiso({
    required String solicitudId,
    required EstadoAprobacion nuevoEstado,
    String? comentario,
  }) async {
    try {
      await _supabase
          .from('solicitudes_permisos')
          .update({
            'estado': nuevoEstado.name,
            'aprobado_por_id': _supabase.auth.currentUser!.id,
            'fecha_resolucion': DateTime.now().toIso8601String(),
            'comentario_resolucion': comentario,
          })
          .eq('id', solicitudId);
    } on PostgrestException catch (e) {
      throw Exception('Error resolviendo permiso: ${e.message}');
    }
  }

  /// Obtiene permisos pendientes de aprobación para el Manager.
  Future<List<SolicitudPermisoModel>> getPermisosPendientes() async {
    try {
      return await _supabase
          .from('solicitudes_permisos')
          .select()
          .eq('estado', EstadoAprobacion.pendiente.name)
          .order('creado_en', ascending: true)
          .withConverter<List<SolicitudPermisoModel>>(
            (data) =>
                data.map((e) => SolicitudPermisoModel.fromJson(e)).toList(),
          );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando permisos: ${e.message}');
    }
  }

  // --- DASHBOARD REAL-TIME ---

  /// Stream para el Dashboard del Manager: Ver quién está trabajando AHORA.
  /// Escucha cambios (INSERT/UPDATE) en la tabla registros_asistencia.
  ///
  /// Filtramos por fecha actual en el cliente porque Realtime streams
  /// tienen limitaciones de filtrado complejo en el servidor comparado con REST.
  Stream<List<Map<String, dynamic>>> streamAsistenciaHoy() {
    // Nota: 'stream' devuelve List<Map<String, dynamic>>, la conversión a Model
    // se debe hacer en la capa de UI o Provider para no bloquear el Stream.
    return _supabase
        .from('registros_asistencia')
        .stream(primaryKey: ['id'])
        .order('fecha_hora_marcacion')
        .map((event) {
          // Filtro ligero en cliente: Solo registros de hoy
          final hoy = DateTime.now();
          return event.where((registro) {
            final fecha = DateTime.parse(registro['fecha_hora_marcacion']);
            return fecha.year == hoy.year &&
                fecha.month == hoy.month &&
                fecha.day == hoy.day;
          }).toList();
        });
  }

  // --- HELPERS PRIVADOS ---

  /// Obtiene el ID de la organización del usuario actual cacheado o de DB.
  /// Necesario para inserts manuales donde RLS requiere el dato explícito
  /// o para validaciones dobles.
  Future<String> _getOrgIdUsuarioActual() async {
    // Opción 1: Obtener de metadata del usuario (Si se guardó al login)
    // Opción 2: Query rápida
    final data = await _supabase
        .from('perfiles')
        .select('organizacion_id')
        .eq('id', _supabase.auth.currentUser!.id)
        .single();
    return data['organizacion_id'] as String;
  }
}

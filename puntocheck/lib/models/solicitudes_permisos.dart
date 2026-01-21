import 'package:puntocheck/models/enums.dart';

class SolicitudesPermisos {
  final String id;
  final String perfilId;
  final String organizacionId; // Restaurado
  final TipoPermiso tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int diasTotales; // Restaurado
  final String? motivo; // Motivo "corto" o título
  final String? motivoDetalle; // Restaurado
  final String?
  documentoSoporteUrl; // Renombrado de documentoAdjuntoUrl para coincidir con el uso
  final EstadoAprobacion? estado;
  final String? aprobadoPorId;
  final String? aprobadoPorNombre;

  // Campos de resolución
  final DateTime? fechaResolucion; // Restaurado
  final String? comentarioResolucion; // Restaurado

  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  // Campos extras para UI (joins)
  final String? solicitanteNombreCompleto;
  final String? solicitanteFotoUrl;

  // Getter de compatibilidad
  String get solicitanteId => perfilId;

  SolicitudesPermisos({
    required this.id,
    required this.perfilId,
    required this.organizacionId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diasTotales,
    this.motivo,
    this.motivoDetalle,
    this.documentoSoporteUrl,
    this.estado,
    this.aprobadoPorId,
    this.aprobadoPorNombre,
    this.fechaResolucion,
    this.comentarioResolucion,
    this.creadoEn,
    this.actualizadoEn,
    this.solicitanteNombreCompleto,
    this.solicitanteFotoUrl,
  });

  factory SolicitudesPermisos.fromJson(Map<String, dynamic> json) {
    // Helper para parsear Enum Tipo (usa el de enums.dart)
    TipoPermiso parseTipo(String? val) {
      if (val == null) return TipoPermiso.otro;
      return TipoPermiso.values.firstWhere(
        (e) => e.name == val || e.value == val,
        orElse: () => TipoPermiso.otro,
      );
    }

    // Helper para parsear Enum Estado (usa el de enums.dart)
    EstadoAprobacion? parseEstado(String? val) {
      if (val == null) return null;
      return EstadoAprobacion.values.firstWhere(
        (e) => e.name == val || e.value == val,
        orElse: () => EstadoAprobacion.pendiente,
      );
    }

    // Lógica para extraer nombre del aprobador (JOIN)
    String? nombreAprobador;
    if (json['aprobado_por'] != null && json['aprobado_por'] is Map) {
      final aprobador = json['aprobado_por'];
      nombreAprobador = '${aprobador['nombres']} ${aprobador['apellidos']}';
    }

    // Lógica para datos del solicitante (JOIN)
    String? nombreSolicitante;
    String? fotoSolicitante;

    // Puede venir como 'perfiles' (default join) o 'solicitante' (alias en manager_service)
    final profileData = json['perfiles'] ?? json['solicitante'];
    if (profileData != null && profileData is Map) {
      nombreSolicitante =
          '${profileData['nombres']} ${profileData['apellidos']}';
      fotoSolicitante = profileData['foto_url'];
    }

    return SolicitudesPermisos(
      id: json['id']?.toString() ?? '',
      perfilId: json['perfil_id']?.toString() ?? '',
      organizacionId: json['organizacion_id']?.toString() ?? '',
      tipo: parseTipo(json['tipo']),
      fechaInicio:
          DateTime.tryParse(json['fecha_inicio'] ?? '') ?? DateTime.now(),
      fechaFin: DateTime.tryParse(json['fecha_fin'] ?? '') ?? DateTime.now(),
      diasTotales: json['dias_totales'] is int
          ? json['dias_totales']
          : int.tryParse(json['dias_totales']?.toString() ?? '0') ?? 0,
      motivo: json['motivo'], // A veces usado como título
      motivoDetalle: json['motivo_detalle'],
      documentoSoporteUrl:
          json['documento_url'] ??
          json['documento_adjunto_url'], // Soporte para ambos nombres de columna por si acaso
      estado: parseEstado(json['estado']),
      aprobadoPorId: json['aprobado_por_id']?.toString(),
      aprobadoPorNombre: nombreAprobador,
      fechaResolucion: DateTime.tryParse(json['fecha_resolucion'] ?? ''),
      comentarioResolucion: json['comentario_resolucion'],
      creadoEn: DateTime.tryParse(json['created_at'] ?? ''),
      actualizadoEn: DateTime.tryParse(json['updated_at'] ?? ''),
      solicitanteNombreCompleto: nombreSolicitante,
      solicitanteFotoUrl: fotoSolicitante,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perfil_id': perfilId,
      'organizacion_id': organizacionId,
      'tipo': tipo
          .value, // Usar value de enums.dart preferiblemente, o name si es consistente
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'dias_totales': diasTotales,
      'motivo': motivo,
      'motivo_detalle': motivoDetalle,
      'documento_url':
          documentoSoporteUrl, // Usamos documento_url para coincidir con logs que sugerian esto
      'estado': estado?.value,
      'aprobado_por_id': aprobadoPorId,
      'fecha_resolucion': fechaResolucion?.toIso8601String(),
      'comentario_resolucion': comentarioResolucion,
    };
  }
}

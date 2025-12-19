import 'enums.dart';

class AlertasCumplimiento {
  final String id;
  final String organizacionId;
  final String? empleadoId;
  final String tipoIncumplimiento;
  final Map<String, dynamic>? detalleTecnico; // JSONB
  final GravedadAlerta? gravedad;
  final String? estado;
  final String? justificacionAdmin;
  final String? atendidoPorId;
  final DateTime? fechaDeteccion;
  final DateTime? actualizadoEn;

  // Datos embebidos (cuando se hace JOIN con perfiles, etc.)
  final String? empleadoNombres;
  final String? empleadoApellidos;
  final String? empleadoSucursalId;

  AlertasCumplimiento({
    required this.id,
    required this.organizacionId,
    this.empleadoId,
    required this.tipoIncumplimiento,
    this.detalleTecnico,
    this.gravedad,
    this.estado,
    this.justificacionAdmin,
    this.atendidoPorId,
    this.fechaDeteccion,
    this.actualizadoEn,
    this.empleadoNombres,
    this.empleadoApellidos,
    this.empleadoSucursalId,
  });

  factory AlertasCumplimiento.fromJson(Map<String, dynamic> json) {
    final empleado =
        (json['empleado'] as Map<String, dynamic>?) ??
        (json['perfiles'] as Map<String, dynamic>?);

    return AlertasCumplimiento(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      empleadoId: json['empleado_id'],
      tipoIncumplimiento:
          (json['tipo_incumplimiento'] ?? json['tipo_alerta'] ?? 'Alerta')
              .toString(),
      detalleTecnico: json['detalle_tecnico'],
      gravedad: json['gravedad'] != null
          ? GravedadAlerta.fromString(json['gravedad'].toString())
          : null,
      estado: json['estado'],
      justificacionAdmin:
          (json['justificacion_admin'] ?? json['justificacion_auditor'])
              ?.toString(),
      atendidoPorId: json['atendido_por_id'],
      fechaDeteccion: json['fecha_deteccion'] != null
          ? DateTime.parse(json['fecha_deteccion'].toString())
          : (json['creado_en'] != null
              ? DateTime.parse(json['creado_en'].toString())
              : null),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'].toString())
          : null,
      empleadoNombres: empleado?['nombres']?.toString(),
      empleadoApellidos: empleado?['apellidos']?.toString(),
      empleadoSucursalId: empleado?['sucursal_id']?.toString(),
    );
  }

  String? get empleadoNombreCompleto {
    final nombres = empleadoNombres?.trim();
    final apellidos = empleadoApellidos?.trim();
    if ((nombres == null || nombres.isEmpty) && (apellidos == null || apellidos.isEmpty)) {
      return null;
    }
    return [nombres, apellidos].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
  }
}

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
  });

  factory AlertasCumplimiento.fromJson(Map<String, dynamic> json) {
    return AlertasCumplimiento(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      empleadoId: json['empleado_id'],
      tipoIncumplimiento: json['tipo_incumplimiento'],
      detalleTecnico: json['detalle_tecnico'],
      gravedad: json['gravedad'] != null
          ? GravedadAlerta.fromString(json['gravedad'])
          : null,
      estado: json['estado'],
      justificacionAdmin: json['justificacion_admin'],
      atendidoPorId: json['atendido_por_id'],
      fechaDeteccion: json['fecha_deteccion'] != null
          ? DateTime.parse(json['fecha_deteccion'])
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'])
          : null,
    );
  }
}

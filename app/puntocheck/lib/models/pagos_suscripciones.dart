import 'enums.dart';

class PagosSuscripciones {
  final String id;
  final String organizacionId;
  final String planId;
  final double monto;
  final String comprobanteUrl;
  final String? referenciaBancaria;
  final EstadoPago? estado; // Mapeado al Enum Dart
  final String? validadoPorId;
  final String? observaciones;
  final DateTime? fechaPago;
  final DateTime? fechaValidacion;

  PagosSuscripciones({
    required this.id,
    required this.organizacionId,
    required this.planId,
    required this.monto,
    required this.comprobanteUrl,
    this.referenciaBancaria,
    this.estado,
    this.validadoPorId,
    this.observaciones,
    this.fechaPago,
    this.fechaValidacion,
  });

  factory PagosSuscripciones.fromJson(Map<String, dynamic> json) {
    return PagosSuscripciones(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      planId: json['plan_id'],

      // PostgreSQL 'numeric' suele venir como num en JSON, lo forzamos a double
      monto: (json['monto'] as num).toDouble(),

      comprobanteUrl: json['comprobante_url'],
      referenciaBancaria: json['referencia_bancaria'],

      // Mapeo del String de Supabase al Enum de Dart
      estado: json['estado'] != null
          ? EstadoPago.fromString(json['estado'])
          : null,

      validadoPorId: json['validado_por_id'],
      observaciones: json['observaciones'],

      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'])
          : null,

      fechaValidacion: json['fecha_validacion'] != null
          ? DateTime.parse(json['fecha_validacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizacion_id': organizacionId,
    'plan_id': planId,
    'monto': monto,
    'comprobante_url': comprobanteUrl,
    'referencia_bancaria': referenciaBancaria,
    'estado': estado?.value, // Enviamos el string ('pendiente', etc.)
    'validado_por_id': validadoPorId,
    'observaciones': observaciones,
    'fecha_pago': fechaPago?.toIso8601String(),
    'fecha_validacion': fechaValidacion?.toIso8601String(),
  };
}

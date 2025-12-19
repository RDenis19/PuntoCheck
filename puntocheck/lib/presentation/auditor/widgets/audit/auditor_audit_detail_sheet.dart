import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/auditoria_log.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAuditDetailSheet extends StatelessWidget {
  final AuditoriaLog log;

  const AuditorAuditDetailSheet({super.key, required this.log});

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final actorName = log.actorNombreCompleto;
    final actorId = log.usuarioResponsableId;

    final before = log.datosAnteriores;
    final after = log.datosNuevos;
    final legacy = log.detalleCambio;

    final beforeText = before == null ? null : _pretty(before);
    final afterText = after == null ? null : _pretty(after);
    final legacyText = (before == null && after == null && legacy != null)
        ? _pretty(legacy)
        : null;

    final headerMeta = [
      if ((log.tablaAfectada ?? '').trim().isNotEmpty) 'Tabla: ${log.tablaAfectada}',
      if ((log.idRegistroAfectado ?? '').trim().isNotEmpty) 'Registro: ${log.idRegistroAfectado}',
    ].join(' · ');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Auditoría del sistema',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      onPressed: () => _copy(context),
                      icon: const Icon(Icons.copy),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _KeyValue('Acción', log.accion),
                if (headerMeta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _KeyValue('Destino', headerMeta),
                ],
                const SizedBox(height: 8),
                _KeyValue(
                  'Actor',
                  actorName != null
                      ? '$actorName${(log.actorRol ?? '').trim().isNotEmpty ? ' · ${log.actorRol}' : ''}'
                      : (actorId ?? '—'),
                ),
                if ((log.ipOrigen ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _KeyValue('IP', log.ipOrigen!.trim()),
                ],
                if ((log.userAgent ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _KeyValue('User-Agent', log.userAgent!.trim()),
                ],
                if (log.creadoEn != null) ...[
                  const SizedBox(height: 8),
                  _KeyValue('Fecha', _fmt.format(log.creadoEn!)),
                ],
                const SizedBox(height: 14),
                if (beforeText != null || afterText != null) ...[
                  _JsonBlock(title: 'Antes', text: beforeText ?? '—'),
                  const SizedBox(height: 10),
                  _JsonBlock(title: 'Después', text: afterText ?? '—'),
                ] else if (legacyText != null) ...[
                  _JsonBlock(title: 'Detalle', text: legacyText),
                ] else ...[
                  const _JsonBlock(title: 'Detalle', text: '—'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final payload = <String, dynamic>{
      'id': log.id,
      'organizacion_id': log.organizacionId,
      'actor_id': log.usuarioResponsableId,
      'accion': log.accion,
      'tabla_afectada': log.tablaAfectada,
      'registro_id': log.idRegistroAfectado,
      'ip': log.ipOrigen,
      'user_agent': log.userAgent,
      'creado_en': log.creadoEn?.toIso8601String(),
      'datos_anteriores': log.datosAnteriores,
      'datos_nuevos': log.datosNuevos,
      'detalle_cambio': log.detalleCambio,
    };

    await Clipboard.setData(ClipboardData(text: _pretty(payload)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado al portapapeles')),
    );
  }

  static String _pretty(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
          ),
        ),
      ],
    );
  }
}

class _JsonBlock extends StatelessWidget {
  final String title;
  final String text;

  const _JsonBlock({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}

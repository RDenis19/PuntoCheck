import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/employee/views/employee_notifications_view.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeRequestsView extends ConsumerWidget {
  const EmployeeRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(employeePermissionsProvider);
    final notificationsAsync = ref.watch(employeeNotificationsProvider);

    final unread = notificationsAsync.valueOrNull
            ?.where((n) => n['leido'] != true)
            .length ??
        0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Permisos y licencias'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmployeeNotificationsView()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unread > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeePermissionsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async => ref.refresh(employeePermissionsProvider.future),
        child: requestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => _ErrorView(
            message: 'No se pudieron cargar tus solicitudes.\n$e',
            onRetry: () => ref.invalidate(employeePermissionsProvider),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const EmptyState(
                icon: Icons.event_note_outlined,
                title: 'Sin solicitudes',
                message: 'Aún no has solicitado permisos.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _RequestCard(
                  request: req,
                  onTap: () => _openDetailSheet(context, req),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'employee_request_create',
        onPressed: () => _openCreateSheet(context),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Solicitar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePermissionSheet(),
    );
  }

  void _openDetailSheet(BuildContext context, SolicitudesPermisos req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailSheet(request: req),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final SolicitudesPermisos request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = request.estado ?? EstadoAprobacion.pendiente;
    final statusChip = _StatusChip(status: status);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final range = '${dateFmt.format(request.fechaInicio)} → ${dateFmt.format(request.fechaFin)}';

    final hasDoc = request.documentoSoporteUrl != null &&
        request.documentoSoporteUrl!.trim().isNotEmpty;
    final hasResolution = (request.comentarioResolucion ?? '').trim().isNotEmpty;
    final approver = (request.aprobadoPorId ?? '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tipoLabel(request.tipo),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                      fontSize: 15,
                    ),
                  ),
                ),
                statusChip,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              range,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaPill(
                  icon: Icons.calendar_today_outlined,
                  label: 'Días',
                  value: '${request.diasTotales}',
                ),
                if (hasDoc)
                  const _MetaPill(
                    icon: Icons.attach_file,
                    label: 'Documento',
                    value: 'Adjunto',
                  ),
                if (approver.isNotEmpty && status != EstadoAprobacion.pendiente)
                  _MetaPill(
                    icon: Icons.person_outline,
                    label: 'Decidió',
                    value: _shortId(approver),
                  ),
              ],
            ),
            if (hasResolution) ...[
              const SizedBox(height: 10),
              Text(
                request.comentarioResolucion!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestDetailSheet extends StatelessWidget {
  const _RequestDetailSheet({required this.request});

  final SolicitudesPermisos request;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final status = request.estado ?? EstadoAprobacion.pendiente;
    final doc = (request.documentoSoporteUrl ?? '').trim();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Detalle de solicitud',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _tipoLabel(request.tipo),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Fechas',
                value: '${dateFmt.format(request.fechaInicio)} → ${dateFmt.format(request.fechaFin)}',
              ),
              _DetailRow(label: 'Días totales', value: request.diasTotales.toString()),
              _DetailRow(
                label: 'Motivo',
                value: (request.motivoDetalle ?? '').trim().isEmpty
                    ? '—'
                    : request.motivoDetalle!.trim(),
              ),
              if (request.aprobadoPorId != null) _DetailRow(label: 'Aprobado por', value: request.aprobadoPorId!),
              if ((request.comentarioResolucion ?? '').trim().isNotEmpty)
                _DetailRow(label: 'Comentario', value: request.comentarioResolucion!.trim()),
              if (doc.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailRow(label: 'Documento', value: 'Adjunto'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copia el path del documento desde el panel de admin si lo necesitas.')),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Ver documento'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePermissionSheet extends ConsumerStatefulWidget {
  const _CreatePermissionSheet();

  @override
  ConsumerState<_CreatePermissionSheet> createState() => _CreatePermissionSheetState();
}

class _CreatePermissionSheetState extends ConsumerState<_CreatePermissionSheet> {
  final _formKey = GlobalKey<FormState>();

  TipoPermiso? _tipo;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _motivo;
  File? _documento;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(employeePermissionControllerProvider).isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final days = _daysInclusive();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Nueva solicitud',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TipoPermiso>(
                    key: ValueKey(_tipo),
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoPermiso.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_tipoLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _tipo = v),
                    validator: (v) => v == null ? 'Selecciona un tipo' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Fecha inicio',
                          value: _fechaInicio,
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Fecha fin',
                          value: _fechaFin,
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  if (days != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Días totales: $days',
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo / explicación (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _motivo = v,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _documento != null ? 'Documento adjunto' : 'Adjuntar documento (PDF/JPG/PNG)',
                    ),
                  ),
                  if (_documento != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _documento!.path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.neutral600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar',
                          onPressed: isLoading ? null : () => setState(() => _documento = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar solicitud',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _daysInclusive() {
    if (_fechaInicio == null || _fechaFin == null) return null;
    final start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
    final end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
    if (end.isBefore(start)) return null;
    return end.difference(start).inDays + 1;
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? (_fechaInicio ?? DateTime.now()) : (_fechaFin ?? _fechaInicio ?? DateTime.now());
    final first = DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = picked;
        }
      } else {
        _fechaFin = picked;
        if (_fechaInicio != null && _fechaFin!.isBefore(_fechaInicio!)) {
          _fechaInicio = _fechaFin;
        }
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withReadStream: false,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() => _documento = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == null) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fechas de inicio y fin')),
      );
      return;
    }

    try {
      await ref.read(employeePermissionControllerProvider.notifier).createRequest(
            tipo: _tipo!,
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            motivoDetalle: _motivo,
            documento: _documento,
          );

      final state = ref.read(employeePermissionControllerProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Error desconocido');
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value!) : 'Seleccionar',
          style: const TextStyle(color: AppColors.neutral700),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.neutral900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EstadoAprobacion status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: AppColors.errorRed)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

(Color, String) _statusStyle(EstadoAprobacion status) {
  switch (status) {
    case EstadoAprobacion.aprobadoManager:
    case EstadoAprobacion.aprobadoRrhh:
      return (AppColors.successGreen, 'Aprobado');
    case EstadoAprobacion.rechazado:
      return (AppColors.errorRed, 'Rechazado');
    case EstadoAprobacion.canceladoUsuario:
      return (AppColors.neutral600, 'Cancelado');
    case EstadoAprobacion.pendiente:
      return (AppColors.warningOrange, 'Pendiente');
  }
}

String _tipoLabel(TipoPermiso tipo) {
  switch (tipo) {
    case TipoPermiso.enfermedad:
      return 'Enfermedad';
    case TipoPermiso.vacaciones:
      return 'Vacaciones';
    case TipoPermiso.calamidadDomestica:
      return 'Calamidad doméstica';
    case TipoPermiso.maternidadPaternidad:
      return 'Maternidad/Paternidad';
    case TipoPermiso.legalVotacion:
      return 'Permiso legal (votación)';
    case TipoPermiso.otro:
      return 'Otro';
  }
}


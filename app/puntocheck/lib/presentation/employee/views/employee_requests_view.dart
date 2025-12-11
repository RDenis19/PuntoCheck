import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/enums.dart';

class EmployeeRequestsView extends ConsumerWidget {
  const EmployeeRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(employeePermissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: permissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (List<SolicitudesPermisos> requests) {
          if (requests.isEmpty) {
            return const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Sin solicitudes',
              message: 'No has solicitado permisos aún.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          req.tipo.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusChip(req.estado),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${req.diasTotales} días • ${req.fechaInicio.day}/${req.fechaInicio.month} - ${req.fechaFin.day}/${req.fechaFin.month}',
                      style: const TextStyle(color: AppColors.neutral600),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Solicitar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePermissionSheet(),
    );
  }

  Widget _buildStatusChip(EstadoAprobacion? status) {
    Color color;
    String label;
    switch (status) {
      case EstadoAprobacion.aprobadoManager:
      case EstadoAprobacion.aprobadoRrhh:
        color = AppColors.successGreen;
        label = 'Aprobado';
        break;
      case EstadoAprobacion.rechazado:
        color = AppColors.errorRed;
        label = 'Rechazado';
        break;
      default:
        color = AppColors.warningOrange;
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
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
                          fontWeight: FontWeight.bold,
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
                    value: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de permiso',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoPermiso.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name.replaceAll('_', ' ')),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _motivo = v,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_documento != null ? 'Documento adjunto' : 'Adjuntar documento'),
                  ),
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
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? (_fechaInicio ?? DateTime.now()) : (_fechaFin ?? _fechaInicio ?? DateTime.now());
    final first = isStart ? DateTime.now().subtract(const Duration(days: 1)) : (_fechaInicio ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
          if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
            _fechaFin = picked;
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withReadStream: false,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _documento = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fechas de inicio y fin')),
      );
      return;
    }
    final dias = _fechaFin!.difference(_fechaInicio!).inDays.abs() + 1;

    String? docUrl;
    try {
      if (_documento != null) {
        docUrl = await ref.read(employeeServiceProvider).uploadDocument(_documento!);
      }

      await ref.read(employeePermissionControllerProvider.notifier).create(
            tipo: _tipo!,
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
            diasTotales: dias,
            motivoDetalle: _motivo,
            documentoUrl: docUrl,
          );

      final state = ref.read(employeePermissionControllerProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Error desconocido');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

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

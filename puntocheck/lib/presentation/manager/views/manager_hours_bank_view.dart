import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/presentation/admin/widgets/hours_bank_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de banco de horas del equipo del Manager.
///
/// Permite al manager:
/// - Ver movimientos de horas del equipo
/// - Filtrar por empleado
/// - Ver detalles (horas, concepto, aprobador)
///
/// Reutiliza `HoursBankCard` del Admin (sin duplicar código).
class ManagerHoursBankView extends ConsumerStatefulWidget {
  const ManagerHoursBankView({super.key});

  @override
  ConsumerState<ManagerHoursBankView> createState() =>
      _ManagerHoursBankViewState();
}

class _ManagerHoursBankViewState extends ConsumerState<ManagerHoursBankView> {
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final hoursBankAsync = ref.watch(
      managerTeamHoursBankProvider(_selectedEmployeeId),
    );
    final teamAsync = ref.watch(
      managerTeamAllProvider(null),
    ); // null = todo el equipo (incluye inactivos/eliminados)
    final controllerState = ref.watch(managerHoursBankControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Horas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(managerTeamHoursBankProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Nuevo movimiento',
            onPressed: () => _openNewMovementSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por empleado
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por empleado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 8),
                teamAsync.when(
                  data: (team) => DropdownButtonFormField<String?>(
                    key: ValueKey(
                      'employee-filter-${_selectedEmployeeId ?? 'all'}',
                    ),
                    initialValue: _selectedEmployeeId,
                    decoration: InputDecoration(
                      hintText: 'Todos los empleados',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutral300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutral300,
                        ),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los empleados'),
                      ),
                      ...team.map(
                        (employee) => DropdownMenuItem<String?>(
                          value: employee.id,
                          child: Text(employee.nombreCompleto),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error cargando equipo'),
                ),
              ],
            ),
          ),

          // Lista de movimientos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(managerTeamHoursBankProvider);
              },
              color: AppColors.primaryRed,
              child: hoursBankAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return EmptyState(
                      icon: Icons.access_time_rounded,
                      title: 'Sin movimientos',
                      message: _selectedEmployeeId != null
                          ? 'Este empleado no tiene movimientos de horas'
                          : 'No hay movimientos de horas registrados',
                      actionLabel: controllerState.isLoading
                          ? null
                          : 'Registrar movimiento',
                      onAction: controllerState.isLoading
                          ? null
                          : () => _openNewMovementSheet(context),
                    );
                  }

                  final teamMap = <String, String>{
                    for (final p in teamAsync.valueOrNull ?? const [])
                      p.id: p.nombreCompleto,
                  };

                  // Calcular balance total
                  final totalHours = records.fold<double>(
                    0.0,
                    (sum, record) => sum + record.cantidadHoras,
                  );

                  return Column(
                    children: [
                      // Card de resumen
                      _SummaryCard(
                        totalHours: totalHours,
                        recordCount: records.length,
                      ),

                      // Lista de registros
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];

                            final employeeName =
                                teamMap[record.empleadoId] ?? 'Empleado';

                            // Reutilizar HoursBankCard del Admin
                            return HoursBankCard(
                              record: record,
                              employeeName: employeeName,
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => _HoursBankDetailSheet(
                                    record: record,
                                    employeeName: employeeName,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error cargando banco de horas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.neutral700),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.invalidate(managerTeamHoursBankProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNewMovementSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HoursBankEntrySheet(
        preselectedEmployeeId: _selectedEmployeeId,
        onCreated: () {
          ref.invalidate(managerTeamHoursBankProvider(_selectedEmployeeId));
        },
      ),
    );
  }
}

// ============================================================================
// Card de resumen
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final double totalHours;
  final int recordCount;

  const _SummaryCard({required this.totalHours, required this.recordCount});

  @override
  Widget build(BuildContext context) {
    final isPositive = totalHours >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  AppColors.successGreen,
                  AppColors.successGreen.withValues(alpha: 0.85),
                ]
              : [
                  AppColors.errorRed,
                  AppColors.errorRed.withValues(alpha: 0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.successGreen : AppColors.errorRed)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '${isPositive ? '+' : ''}${totalHours.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'horas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$recordCount ${recordCount == 1 ? 'movimiento' : 'movimientos'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursBankEntrySheet extends ConsumerStatefulWidget {
  final String? preselectedEmployeeId;
  final VoidCallback onCreated;

  const _HoursBankEntrySheet({
    required this.preselectedEmployeeId,
    required this.onCreated,
  });

  @override
  ConsumerState<_HoursBankEntrySheet> createState() =>
      _HoursBankEntrySheetState();
}

class _HoursBankDetailSheet extends StatelessWidget {
  final BancoHorasCompensatorias record;
  final String employeeName;

  const _HoursBankDetailSheet({
    required this.record,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = record.cantidadHoras >= 0;
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPositive ? Icons.add_rounded : Icons.remove_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              _DetailRow(
                label: 'Horas',
                value:
                    '${isPositive ? '+' : ''}${record.cantidadHoras.toStringAsFixed(1)}',
              ),
              _DetailRow(label: 'Concepto', value: record.concepto),
              if (record.aceptaRenunciaPago == true)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Acepta renuncia de pago',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (record.aprobadoPorId != null)
                _DetailRow(label: 'Aprobado por', value: record.aprobadoPorId!),
              if (record.creadoEn != null)
                _DetailRow(
                  label: 'Creado',
                  value: record.creadoEn!.toIso8601String(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral700,
              ),
            ),
          ),
          const SizedBox(width: 12),
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

class _HoursBankEntrySheetState extends ConsumerState<_HoursBankEntrySheet> {
  final _hoursController = TextEditingController(text: '8');
  final _conceptController = TextEditingController(
    text: 'Día compensatorio otorgado',
  );

  bool _isDebit = true;
  bool _acceptsWaiver = false;
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.preselectedEmployeeId;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(managerTeamProvider(null));
    final controllerState = ref.watch(managerHoursBankControllerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nuevo movimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controllerState.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Empleado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 8),
              teamAsync.when(
                data: (team) => DropdownButtonFormField<String>(
                  key: ValueKey('employee-entry-${_employeeId ?? 'none'}'),
                  initialValue: _employeeId,
                  items: [
                    for (final e in team)
                      DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombreCompleto),
                      ),
                  ],
                  onChanged: controllerState.isLoading
                      ? null
                      : (v) => setState(() => _employeeId = v),
                  decoration: InputDecoration(
                    hintText: 'Selecciona un empleado',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neutral300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neutral300),
                    ),
                  ),
                ),
                loading: () =>
                    const LinearProgressIndicator(color: AppColors.primaryRed),
                error: (e, _) => Text(
                  'Error cargando equipo: $e',
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tipo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Crédito (+)'),
                      selected: !_isDebit,
                      onSelected: controllerState.isLoading
                          ? null
                          : (v) {
                              if (!v) return;
                              setState(() {
                                _isDebit = false;
                                _conceptController.text =
                                    'Horas extra cargadas';
                                if (_hoursController.text.trim().isEmpty) {
                                  _hoursController.text = '1';
                                }
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Débito (-)'),
                      selected: _isDebit,
                      onSelected: controllerState.isLoading
                          ? null
                          : (v) {
                              if (!v) return;
                              setState(() {
                                _isDebit = true;
                                _conceptController.text =
                                    'Día compensatorio otorgado';
                                if (_hoursController.text.trim().isEmpty) {
                                  _hoursController.text = '8';
                                }
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: !controllerState.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Horas',
                        prefixIcon: const Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _conceptController,
                      enabled: !controllerState.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Concepto',
                        prefixIcon: const Icon(Icons.short_text_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepta renuncia de pago',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Marca si el empleado acepta compensar sin pago extra',
                ),
                value: _acceptsWaiver,
                onChanged: controllerState.isLoading
                    ? null
                    : (v) => setState(() => _acceptsWaiver = v),
                activeThumbColor: AppColors.primaryRed,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controllerState.isLoading ? null : _submit,
                  icon: controllerState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    controllerState.isLoading ? 'Guardando...' : 'Guardar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final employeeId = _employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      _snack('Selecciona un empleado', isError: true);
      return;
    }

    final rawHours = _hoursController.text.trim().replaceAll(',', '.');
    final hours = double.tryParse(rawHours);
    if (hours == null || hours <= 0) {
      _snack('Ingresa una cantidad de horas válida', isError: true);
      return;
    }

    final concept = _conceptController.text.trim();
    if (concept.isEmpty) {
      _snack('Ingresa un concepto', isError: true);
      return;
    }

    final signedHours = _isDebit ? -hours : hours;
    final controller = ref.read(managerHoursBankControllerProvider.notifier);

    await controller.registerHours(
      employeeId: employeeId,
      hours: signedHours,
      concept: concept,
      acceptsWaiver: _acceptsWaiver,
    );

    final state = ref.read(managerHoursBankControllerProvider);
    if (state.hasError) {
      _snack(
        'No se pudo registrar. Si tu rol no tiene permisos, solicita al Org Admin.',
        isError: true,
      );
      return;
    }

    widget.onCreated();
    if (!mounted) return;
    Navigator.pop(context);
    _snack('Movimiento registrado');
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

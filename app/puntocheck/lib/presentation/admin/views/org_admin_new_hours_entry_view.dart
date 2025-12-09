import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/widgets/employee_selector.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/hours_bank_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista para crear un nuevo registro de banco de horas
class OrgAdminNewHoursEntryView extends ConsumerStatefulWidget {
  const OrgAdminNewHoursEntryView({super.key});

  @override
  ConsumerState<OrgAdminNewHoursEntryView> createState() =>
      _OrgAdminNewHoursEntryViewState();
}

class _OrgAdminNewHoursEntryViewState
    extends ConsumerState<OrgAdminNewHoursEntryView> {
  final _formKey = GlobalKey<FormState>();
  final _horasController = TextEditingController();
  final _conceptoController = TextEditingController();

  String? _selectedEmployeeId;
  bool _aceptaRenuncia = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _horasController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Registro de Horas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Empleado
                EmployeeSelector(
                  label: 'Empleado',
                  selectedEmployeeId: _selectedEmployeeId,
                  onChanged: (value) {
                    setState(() => _selectedEmployeeId = value);
                  },
                  showAllOption: false,
                ),

                const SizedBox(height: 20),

                // Cantidad de horas
                TextFormField(
                  controller: _horasController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad de Horas',
                    hintText: 'Ej: 2.5 (positivo) o -1.5 (negativo)',
                    prefixIcon: const Icon(Icons.access_time_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Usa valores positivos para acumular, negativos para descontar',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa la cantidad de horas';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Concepto
                TextFormField(
                  controller: _conceptoController,
                  decoration: InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Ej: Horas extras turno nocturno',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el concepto';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Acepta renuncia pago
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.infoBlue.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _aceptaRenuncia,
                    onChanged: (value) {
                      setState(() => _aceptaRenuncia = value ?? false);
                    },
                    title: const Text(
                      'Acepta renuncia de pago por estas horas',
                      style: TextStyle(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),

                const SizedBox(height: 32),

                // Botón guardar
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Registro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un empleado')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizacionId;
      if (orgId == null) throw Exception('No org ID');

      final hours = double.parse(_horasController.text);

      await HoursBankService.instance.createHoursEntry(
        organizacionId: orgId,
        empleadoId: _selectedEmployeeId!,
        cantidadHoras: hours,
        concepto: _conceptoController.text.trim(),
        aceptaRenunciaPago: _aceptaRenuncia,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro creado exitosamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear registro: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

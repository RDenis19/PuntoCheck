import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeAttendanceView extends ConsumerWidget {
  const EmployeeAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(employeeAttendanceHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (List<RegistrosAsistencia> history) {
          if (history.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Sin registros',
              message: 'Tu historial de asistencia aparecera aqui.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              final date = record.fechaHoraMarcacion;
              final tipo = record.tipoRegistro ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        DateFormat('HH:mm').format(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getColorForType(tipo),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _getColorForType(tipo).withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (index != history.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: AppColors.neutral200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(tipo),
                              color: _getColorForType(tipo),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tipo.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getColorForType(tipo),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                color: AppColors.neutral500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'entrada':
        return AppColors.successGreen;
      case 'salida':
        return AppColors.primaryRed;
      case 'inicio_break':
        return AppColors.warningOrange;
      default:
        return AppColors.neutral500;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'entrada':
        return Icons.login;
      case 'salida':
        return Icons.logout;
      default:
        return Icons.coffee;
    }
  }
}

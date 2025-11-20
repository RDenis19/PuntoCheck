import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmpleadoDetalleView extends StatelessWidget {
  const EmpleadoDetalleView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _DetailStat(label: 'Asistencia', value: '95.5%'),
      _DetailStat(label: 'Presente', value: '21/22'),
      _DetailStat(label: 'Tardes', value: '1'),
      _DetailStat(label: 'Total días', value: '22'),
    ];

    final historial = [
      {
        'dia': 'Jueves 31/10/2025',
        'estado': 'A tiempo',
        'color': AppColors.successGreen,
      },
      {
        'dia': 'Miércoles 30/10/2025',
        'estado': 'Tarde',
        'color': AppColors.warningOrange,
      },
      {
        'dia': 'Martes 29/10/2025',
        'estado': 'A tiempo',
        'color': AppColors.successGreen,
      },
      {
        'dia': 'Lunes 28/10/2025',
        'estado': 'A tiempo',
        'color': AppColors.successGreen,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Empleado'),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final stat = stats[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.label,
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stat.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildLastAttendance(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Asistencias (Últimos 7 días)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: historial
                        .map(
                          (dia) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dia['dia']! as String,
                                  style: const TextStyle(
                                    color: AppColors.backgroundDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (dia['color']! as Color).withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    dia['estado']! as String,
                                    style: TextStyle(
                                      color: dia['color']! as Color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // TODO(backend): mostrar aquí los registros reales de los últimos días.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDark,
            AppColors.black.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.white,
            child: Icon(
              Icons.person,
              color: AppColors.backgroundDark,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pablo Criollo',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'pavincrik@gmail.com · +593 999 888 777',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: 'Activo', color: AppColors.successGreen),
              const SizedBox(width: 8),
              _Chip(label: 'Empleado', color: AppColors.infoBlue),
            ],
          ),
          const SizedBox(height: 8),
          // TODO(backend): cargar datos del empleado desde su ID para mostrar nombre, contacto y estado real.
        ],
      ),
    );
  }

  Widget _buildLastAttendance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Última Asistencia',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.backgroundDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _AttendanceDetail(label: 'Fecha', value: '31/10/2025'),
                _AttendanceDetail(label: 'Entrada', value: '08:45'),
                _AttendanceDetail(label: 'Salida', value: '17:30'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // TODO(backend): traer el registro más reciente desde la API de asistencias.
        ],
      ),
    );
  }
}

class _AttendanceDetail extends StatelessWidget {
  const _AttendanceDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.backgroundDark,
          ),
        ),
      ],
    );
  }
}

class _DetailStat {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

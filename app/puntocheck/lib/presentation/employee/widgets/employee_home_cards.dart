import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeHomeCard extends StatelessWidget {
  const EmployeeHomeCard({
    super.key,
    required this.header,
    required this.body,
    this.footer,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          body,
          if (footer != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class CurrentLocationCard extends StatelessWidget {
  const CurrentLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(backend): los datos de ubicación actual deben venir del servicio de localización
    // y/o backend para auditoría (dirección, coordenadas, precisión).
    return EmployeeHomeCard(
      header: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Ubicación actual',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizar ubicación (mock)')),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dirección',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loja, Av. 18 Noviembre, Mercadillo',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coordenadas',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latitud: -3.9935\nLongitud: -79.2046',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Precisión',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '±5 m (metros)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Toca para ver el mapa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class TodayStatsCard extends StatelessWidget {
  const TodayStatsCard({super.key, this.onFooterTap});

  final VoidCallback? onFooterTap;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): estadísticas del día desde registros de asistencia y horarios.
    return EmployeeHomeCard(
      header: Row(
        children: const [
          Icon(Icons.schedule, color: AppColors.white),
          SizedBox(width: 8),
          Text(
            'Estadísticas de Hoy',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              _statTile('Horas trabajadas', '0h 0m'),
              _statTile('Racha', '5 días'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statTile('Entrada', '8 am'),
              _statTile('Salida', '5 pm'),
            ],
          ),
        ],
      ),
      footer: Center(
        child: TextButton.icon(
          onPressed:
              onFooterTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Horarios de trabajo (mock)')),
                );
              },
          icon: const Icon(
            Icons.calendar_today,
            color: Colors.white70,
            size: 18,
          ),
          label: const Text(
            'Horarios de trabajo',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(backend): lista paginada de asistencias recientes desde el backend.
    return EmployeeHomeCard(
      header: Row(
        children: const [
          Icon(Icons.receipt_long_outlined, color: AppColors.white),
          SizedBox(width: 8),
          Text(
            'Actividad Reciente',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
      body: Column(
        children: const [
          _ActivityItem(
            title: 'Salida registrada',
            time: '17:30',
            subtitle: 'Loja, 18 Noviembre, Mercad…',
            icon: Icons.logout,
          ),
          Divider(color: Colors.white24, height: 16),
          _ActivityItem(
            title: 'Entrada registrada',
            time: '08:00',
            subtitle: 'Loja, 18 Noviembre, Mercad…',
            icon: Icons.login,
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.time,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String time;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

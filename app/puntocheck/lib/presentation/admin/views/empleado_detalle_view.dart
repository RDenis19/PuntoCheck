import 'package:flutter/material.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmpleadoDetalleView extends StatelessWidget {
  const EmpleadoDetalleView({super.key, this.employee});

  final dynamic employee;

  @override
  Widget build(BuildContext context) {
    final profile = employee as Profile?;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalles del Empleado'),
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.black),
          centerTitle: true,
        ),
        body: const Center(child: Text('Empleado no encontrado')),
      );
    }

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
            _buildHeader(profile),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informacion de contacto',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Correo', value: profile.email ?? 'Sin correo'),
                  _InfoRow(label: 'Telefono', value: profile.phone ?? 'Sin telefono'),
                  _InfoRow(label: 'Rol', value: profile.jobTitle),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Historial de asistencias',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Integra el historial desde el modulo de reportes para ver detalle por empleado.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Profile profile) {
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
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.white,
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? 'Sin nombre',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            profile.employeeCode ?? '',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: profile.isActive ? 'Activo' : 'Inactivo', color: AppColors.successGreen),
              const SizedBox(width: 8),
              _Chip(label: profile.isOrgAdmin ? 'Admin' : 'Empleado', color: AppColors.infoBlue),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
          ),
        ],
      ),
    );
  }
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

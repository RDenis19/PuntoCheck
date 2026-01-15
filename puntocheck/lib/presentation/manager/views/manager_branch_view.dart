import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/encargados_sucursales.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/providers/auth_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerBranchView extends ConsumerStatefulWidget {
  const ManagerBranchView({super.key});

  @override
  ConsumerState<ManagerBranchView> createState() => _ManagerBranchViewState();
}

class _ManagerBranchViewState extends ConsumerState<ManagerBranchView> {
  String? _selectedBranchId;

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(managerBranchesProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi sucursal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: branchesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => _ErrorState(
            message: 'Error cargando sucursal: $e',
            onRetry: () => ref.invalidate(managerBranchesProvider),
          ),
          data: (branches) {
            if (branches.isEmpty) {
              return const _EmptyState();
            }

            final selectedId = _selectedBranchId ?? branches.first.id;
            final selectedBranch = branches.firstWhere(
              (b) => b.id == selectedId,
              orElse: () => branches.first,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (branches.length > 1) ...[
                  _BranchPicker(
                    branches: branches,
                    value: selectedId,
                    onChanged: (value) =>
                        setState(() => _selectedBranchId = value),
                  ),
                  const SizedBox(height: 12),
                ],
                _BranchInfoCard(branch: selectedBranch),
                const SizedBox(height: 16),
                _ManagersCard(
                  branchId: selectedBranch.id,
                  currentUserId: currentUserId,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BranchPicker extends StatelessWidget {
  final List<Sucursales> branches;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _BranchPicker({
    required this.branches,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral300, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: const Text('Selecciona una sucursal'),
          items: branches
              .map(
                (b) => DropdownMenuItem<String?>(
                  value: b.id,
                  child: Text(b.nombre, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BranchInfoCard extends StatelessWidget {
  final Sucursales branch;

  const _BranchInfoCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Información de sucursal',
      icon: Icons.store_mall_directory_rounded,
      child: Column(
        children: [
          _InfoRow(label: 'Nombre', value: branch.nombre),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Dirección',
            value: (branch.direccion ?? '').trim().isEmpty
                ? 'Sin dirección'
                : branch.direccion!,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Radio (m)',
            value: branch.radioMetros?.toString() ?? '50',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'QR habilitado',
            value: branch.tieneQrHabilitado == true ? 'Sí' : 'No',
            valueColor: branch.tieneQrHabilitado == true
                ? AppColors.successGreen
                : null,
          ),
        ],
      ),
    );
  }
}

class _ManagersCard extends ConsumerWidget {
  final String branchId;
  final String? currentUserId;

  const _ManagersCard({required this.branchId, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managersAsync = ref.watch(managerBranchManagersProvider(branchId));

    return _CardShell(
      title: 'Encargados de esta sucursal',
      icon: Icons.verified_user_rounded,
      trailing: IconButton(
        tooltip: 'Actualizar',
        onPressed: () =>
            ref.invalidate(managerBranchManagersProvider(branchId)),
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: managersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Error cargando encargados: $e',
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay encargados registrados para esta sucursal.',
                style: TextStyle(color: AppColors.neutral600),
              ),
            );
          }

          return Column(
            children: [
              for (final item in list) ...[
                _ManagerRow(
                  assignment: item,
                  isMe:
                      currentUserId != null && item.managerId == currentUserId,
                ),
                if (item.id != list.last.id) const Divider(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ManagerRow extends StatelessWidget {
  final EncargadosSucursales assignment;
  final bool isMe;

  const _ManagerRow({required this.assignment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final profile = assignment.managerProfile;
    final name = profile == null
        ? assignment.managerId.substring(0, 8)
        : '${profile.nombres} ${profile.apellidos}'.trim();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Tú',
                        style: TextStyle(
                          color: AppColors.infoBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                assignment.activo == false ? 'Inactivo' : 'Activo',
                style: TextStyle(
                  color: assignment.activo == false
                      ? AppColors.neutral600
                      : AppColors.successGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _CardShell({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutral200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.neutral700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.neutral900,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_mall_directory_rounded,
              size: 56,
              color: AppColors.neutral500,
            ),
            SizedBox(height: 12),
            Text(
              'Sin sucursal asignada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pide al administrador que te asigne como encargado de una sucursal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

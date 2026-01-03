import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Widget selector de jefe inmediato (manager)
/// Carga la lista de managers de la organización y permite seleccionar uno
class ManagerSelector extends ConsumerWidget {
  final String? selectedManagerId;
  final ValueChanged<String?> onChanged;
  final String? currentUserId; // Para excluir al usuario actual de la lista

  const ManagerSelector({
    super.key,
    this.selectedManagerId,
    required this.onChanged,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managersAsync = ref.watch(orgAdminManagersProvider);

    return managersAsync.when(
      data: (managers) {
        // Filtrar el usuario actual si está presente
        final filteredManagers = currentUserId != null
            ? managers.where((m) => m.id != currentUserId).toList()
            : managers;

        if (filteredManagers.isEmpty) {
          return _EmptyManagersState(onChanged: onChanged);
        }

        return DropdownButtonFormField<String?>(
          key: ValueKey(selectedManagerId),
          initialValue: selectedManagerId,
          decoration: InputDecoration(
            labelText: 'Jefe inmediato',
            hintText: 'Seleccionar manager',
            prefixIcon: const Icon(Icons.supervisor_account),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin jefe asignado'),
            ),
            ...filteredManagers.map((manager) {
              return DropdownMenuItem<String?>(
                value: manager.id,
                child: Text(
                  manager.nombreCompleto,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: onChanged,
          validator: (value) => null, // Opcional
        );
      },
      loading: () => DropdownButtonFormField<String?>(
        decoration: InputDecoration(
          labelText: 'Jefe inmediato',
          hintText: 'Cargando managers...',
          prefixIcon: const Icon(Icons.supervisor_account),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, _) => _ErrorManagersState(
        error: error.toString(),
        onRetry: () => ref.invalidate(orgAdminManagersProvider),
      ),
    );
  }
}

/// Estado cuando no hay managers disponibles
class _EmptyManagersState extends StatelessWidget {
  final ValueChanged<String?> onChanged;

  const _EmptyManagersState({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: null,
          decoration: InputDecoration(
            labelText: 'Jefe inmediato',
            hintText: 'No hay managers disponibles',
            prefixIcon: const Icon(Icons.supervisor_account),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin jefe asignado'),
            ),
          ],
          onChanged: (value) => onChanged(null),
        ),
        const SizedBox(height: 8),
        const Text(
          'No hay managers creados en la organización',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

/// Estado de error al cargar managers
class _ErrorManagersState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorManagersState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          decoration: InputDecoration(
            labelText: 'Jefe inmediato',
            hintText: 'Error al cargar',
            prefixIcon: const Icon(Icons.error_outline_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: const [],
          onChanged: null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Error cargando managers',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Encabezado rojo para Org Admin con saludo, rol y organizacion.
class AdminHeader extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final String? organizationName;

  const AdminHeader({
    super.key,
    required this.userName,
    required this.roleLabel,
    this.organizationName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (organizationName != null && organizationName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    organizationName!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: Colors.white),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_header.dart';

/// Encabezado reutilizable con el mismo estilo del Super Admin y Admin.
/// Muestra información del Manager con el diseño consistente de gradiente rojo.
class ManagerHeader extends StatelessWidget {
  final String userName;
  final String organizationName;

  const ManagerHeader({
    super.key,
    required this.userName,
    required this.organizationName,
  });

  @override
  Widget build(BuildContext context) {
    return SuperAdminHeader(
      userName: userName,
      roleLabel: 'Manager',
      organizationName: organizationName,
    );
  }
}

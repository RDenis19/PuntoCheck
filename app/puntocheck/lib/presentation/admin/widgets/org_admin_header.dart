import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_header.dart';

/// Encabezado reutilizable con el mismo estilo del Super Admin.
class OrgAdminHeader extends StatelessWidget {
  final String userName;
  final String organizationName;

  const OrgAdminHeader({
    super.key,
    required this.userName,
    required this.organizationName,
  });

  @override
  Widget build(BuildContext context) {
    return SuperAdminHeader(
      userName: userName,
      roleLabel: 'Admin de organización',
      organizationName: organizationName,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_header.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorHeader extends StatelessWidget {
  final String userName;
  final String organizationName;
  final int? unreadNotificationsCount;
  final VoidCallback? onNotificationsPressed;

  const AuditorHeader({
    super.key,
    required this.userName,
    required this.organizationName,
    this.unreadNotificationsCount,
    this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final unread = unreadNotificationsCount ?? 0;

    return SuperAdminHeader(
      userName: userName,
      roleLabel: 'Auditor',
      organizationName: organizationName,
      trailing: onNotificationsPressed == null
          ? null
          : IconButton(
              tooltip: 'Notificaciones',
              onPressed: onNotificationsPressed,
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.secondaryWhite,
                ),
              ),
            ),
    );
  }
}

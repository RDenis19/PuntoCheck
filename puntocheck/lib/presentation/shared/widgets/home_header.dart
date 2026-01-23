import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? roleName;
  final String? organizationName;
  final VoidCallback? onNotificationTap;
  final int notificationCount;

  const HomeHeader({
    super.key,
    required this.userName,
    this.roleName,
    this.organizationName,
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the greeting based on the current hour
    final hour = DateTime.now().hour;
    String greeting = 'Hola';
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    userName.trim().isNotEmpty
                        ? userName.trim()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$greeting, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (roleName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        roleName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (organizationName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        organizationName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action Icon (Notifications)
              if (onNotificationTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: InkWell(
                    onTap: onNotificationTap,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Badge(
                        isLabelVisible: notificationCount > 0,
                        backgroundColor: Colors.white,
                        textColor: AppColors.primaryRed,
                        label: Text(
                          notificationCount > 99 ? '99+' : '$notificationCount',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

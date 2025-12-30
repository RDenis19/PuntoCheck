import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/employee/views/employee_notifications_view.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeNotificationsAction extends ConsumerWidget {
  const EmployeeNotificationsAction({
    super.key,
    this.onPrimary = false,
  });

  /// Cuando el botón se muestra sobre un header rojo/primary.
  final bool onPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(employeeNotificationsProvider);
    final unread =
        notificationsAsync.valueOrNull?.where((n) => n['leido'] != true).length ??
            0;

    final iconColor =
        onPrimary ? Theme.of(context).colorScheme.onPrimary : AppColors.neutral900;
    final badgeBg = onPrimary ? Colors.white : AppColors.primaryRed;
    final badgeFg =
        onPrimary ? Theme.of(context).colorScheme.primary : Colors.white;

    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmployeeNotificationsView()),
        );
      },
      onLongPress: () => ref.invalidate(employeeNotificationsProvider),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor),
          if (unread > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: onPrimary
                      ? null
                      : Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: TextStyle(
                    color: badgeFg,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


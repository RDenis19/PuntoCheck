import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorLeavesHoursView extends StatelessWidget {
  const AuditorLeavesHoursView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'Permisos & banco de horas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                labelColor: AppColors.primaryRed,
                unselectedLabelColor: AppColors.neutral600,
                indicatorColor: AppColors.primaryRed,
                tabs: [
                  Tab(text: 'Permisos'),
                  Tab(text: 'Banco de horas'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyState(
                      title: 'Permisos',
                      message:
                          'Aquí se revisan solicitudes_permisos y su coherencia con asistencia.',
                      icon: Icons.event_note_outlined,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyState(
                      title: 'Banco de horas',
                      message:
                          'Aquí se revisa banco_horas y se cruza con permisos/asistencia.',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


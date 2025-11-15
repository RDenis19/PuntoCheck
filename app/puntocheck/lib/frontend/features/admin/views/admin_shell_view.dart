import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/features/admin/views/admin_home_view.dart';
import 'package:puntocheck/frontend/features/admin/views/horario_admin_view.dart';
import 'package:puntocheck/frontend/features/admin/views/apariencia_app_view.dart';
import 'package:puntocheck/frontend/features/employee/views/settings_view.dart';

class AdminShellView extends StatefulWidget {
  const AdminShellView({super.key});

  @override
  State<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<AdminShellView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminHomeView(),
      const HorarioAdminView(),
      const AparienciaAppView(),
      const AdminSettingsTabView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const icons = [
      Icons.home_outlined,
      Icons.calendar_month_outlined,
      Icons.brush_outlined,
      Icons.settings_outlined,
    ];

    const labels = ['Inicio', 'Horario', 'Editar App', 'Configuración'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(icons.length, (index) {
            final isSelected = index == _currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryRed.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: AppColors.primaryRed, width: 1.4)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        size: 22,
                        color: isSelected ? AppColors.primaryRed : Colors.grey,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? AppColors.primaryRed
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AdminSettingsTabView extends StatelessWidget {
  const AdminSettingsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Configuración Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
          Expanded(child: SettingsView(embedded: true)),
        ],
      ),
    );
  }
}



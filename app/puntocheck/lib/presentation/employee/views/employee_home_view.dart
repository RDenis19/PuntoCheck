import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/shared/widgets/custom_map_widget.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/employee/views/avisos_view.dart';
import 'package:puntocheck/presentation/employee/views/historial_view.dart';
import 'package:puntocheck/presentation/employee/views/settings_view.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_home_cards.dart';
import 'package:puntocheck/providers/app_providers.dart';

class EmployeeHomeView extends ConsumerStatefulWidget {
  const EmployeeHomeView({super.key});
  @override
  ConsumerState<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends ConsumerState<EmployeeHomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context),
          const _MapPlaceholder(),
          const HistorialView(embedded: true),
          const AvisosView(embedded: true),
          const SettingsView(embedded: true),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildRegisterButton(context),
            const SizedBox(height: 24),
            const CurrentLocationCard(),
            TodayStatsCard(
              onFooterTap: () {
                context.push(AppRoutes.horarioTrabajo);
              },
            ),
            const RecentActivityCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final orgAsync = ref.watch(currentOrganizationProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: profileAsync.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola ${profile?.fullName ?? 'Usuario'}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile?.jobTitle ?? 'Empleado'}  ${DateTime.now().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  orgAsync.when(
                    data: (org) => Text(
                      'Organizacion: ${org?.name ?? 'Sin asignar'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const Text(
                      'Organizacion: cargando...',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    error: (_, __) => const Text(
                      'Organizacion: no disponible',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, __) => const Text(
                'Error cargando perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _currentIndex = 3);
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.white,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    // Verificar si ya tiene turno activo
    final activeShiftAsync = ref.watch(activeShiftProvider);
    return activeShiftAsync.when(
      data: (activeShift) {
        final isCheckIn = activeShift == null;
        return Center(
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: isCheckIn ? AppColors.primaryRed : Colors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCheckIn ? AppColors.primaryRed : Colors.orange)
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push(AppRoutes.registroAsistencia);
                },
                borderRadius: BorderRadius.circular(65),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCheckIn ? Icons.login : Icons.logout,
                      color: AppColors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCheckIn ? 'Registrar\nEntrada' : 'Registrar\nSalida',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNav() {
    const icons = <IconData>[
      Icons.home,
      Icons.map_outlined,
      Icons.history,
      Icons.notifications_none,
      Icons.settings_outlined,
    ];
    const labels = <String>['Inicio', 'Mapa', 'Historial', 'Avisos', 'Ajustes'];

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
            final bool isSelected = index == _currentIndex;
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
                        ? AppColors.primaryRed.withOpacity(0.08)
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 📍 Mapa aquí
            Expanded(
              child: const CustomMapWidget(
                showMyLocation: true,
                showMyLocationButton: true,
                initialZoom: 15,
              ),
            ),

            const SizedBox(height: 24),

            Icon(
              Icons.map_outlined,
              size: 72,
              color: AppColors.primaryRed.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mapa en desarrollo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pronto podras ver rutas, oficinas y la ubicación en tiempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),

            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mapa en desarrollo')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Actualizar mapa'),
            ),
          ],
        ),
      ),
    );
  }
}

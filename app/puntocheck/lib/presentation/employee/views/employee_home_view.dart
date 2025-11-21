import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/employee/views/avisos_view.dart';
import 'package:puntocheck/presentation/employee/views/historial_view.dart';
import 'package:puntocheck/presentation/employee/views/settings_view.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_home_cards.dart';
import 'package:puntocheck/providers/auth_provider.dart';
import 'package:puntocheck/providers/attendance_provider.dart';

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
            const SizedBox(height: 16),
            const CurrentLocationCard(),
            TodayStatsCard(
              onFooterTap: () {
                Navigator.pushNamed(context, AppRouter.employeeHorarioTrabajo);
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
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundDark, Color(0xFF062235)],
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
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            // TODO: Mostrar avatar real si existe
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
                    '${profile?.jobTitle ?? 'Empleado'} · ${DateTime.now().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (_, __) => const Text('Error cargando perfil', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
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
                    color: AppColors.primaryRed,
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
          child: GestureDetector(
            onTap: () {
              // Si es check-in, vamos a registro
              // Si es check-out, también vamos a registro (o una vista de salida específica)
              // Por ahora reusamos la vista, pero pasamos argumento o manejamos estado
              // Idealmente RegistroAsistenciaView debería saber si es entrada o salida
              // O pasamos un argumento.
              // Por simplicidad, vamos a la misma vista y ella decide (o le pasamos param)
              Navigator.pushNamed(context, AppRouter.employeeRegistroAsistencia);
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isCheckIn ? AppColors.primaryRed : Colors.orange,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCheckIn ? Icons.login : Icons.logout, 
                    color: AppColors.white, 
                    size: 32
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCheckIn ? 'Registrar\nEntrada' : 'Registrar\nSalida',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 72,
              color: AppColors.primaryRed.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
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
              'Pronto podrás ver rutas, oficinas y la ubicación en tiempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Mapa (mock).')));
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

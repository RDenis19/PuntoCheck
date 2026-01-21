import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/manager/views/manager_person_detail_view.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vista del equipo del manager.
/// Implementa CustomScrollView, Búsqueda Sticky y Acciones Rápidas.
class ManagerTeamView extends ConsumerStatefulWidget {
  const ManagerTeamView({super.key});

  @override
  ConsumerState<ManagerTeamView> createState() => _ManagerTeamViewState();
}

class _ManagerTeamViewState extends ConsumerState<ManagerTeamView> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  bool _includeInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(
      _includeInactive
          ? managerTeamAllProvider(_searchQuery)
          : managerTeamProvider(_searchQuery),
    );

    return Scaffold(
      backgroundColor: AppColors.secondaryWhite,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar con Búsqueda Sticky
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 120, // Altura para título y subtitle
            centerTitle: false,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Equipo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                Text(
                  'Gestión de personal',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _onSearchChanged(),
                              decoration: InputDecoration(
                                hintText: 'Buscar empleado...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.neutral500,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.neutral100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        // Botón de filtro (Activos/Todos) - Simple Loop
                        const SizedBox(width: 8),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(
                                () => _includeInactive = !_includeInactive,
                              );
                            },
                            icon: Icon(
                              _includeInactive
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _includeInactive
                                  ? AppColors.neutral500
                                  : AppColors.primaryRed,
                            ),
                            tooltip: _includeInactive
                                ? 'Ocultar inactivos'
                                : 'Mostrar inactivos',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Lista de Empleados
          teamAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar equipo: $e',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (team) {
              if (team.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: EmptyState(
                      title: 'Sin empleados',
                      message: 'No se encontraron resultados.',
                      icon: Icons.people_outline_rounded,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final employee = team[index];
                    // Lógica de "Working Now" (Simulada o real si tenemos el dato)
                    // Si 'activo' es true, mostramos punto verde, si no gris.
                    // Idealmente verificaríamos si tiene un turno activo AHORA.
                    // Asumiremos 'activo' del perfil por ahora como "Status General".
                    final isOnline = employee.activo == true;

                    return _ManagerTeamMemberTile(
                      employee: employee,
                      isOnline: isOnline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ManagerPersonDetailView(userId: employee.id),
                          ),
                        );
                      },
                    );
                  }, childCount: team.length),
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _ManagerTeamMemberTile extends StatelessWidget {
  final dynamic employee; // Tipo Perfiles
  final bool isOnline;
  final VoidCallback onTap;

  const _ManagerTeamMemberTile({
    required this.employee,
    required this.isOnline,
    required this.onTap,
  });

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = '${employee.nombres} ${employee.apellidos}';
    final cargo = employee.cargo ?? 'Sin cargo';
    final photoUrl = employee.fotoPerfilUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con Status Dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.neutral100,
                      backgroundImage:
                          (photoUrl != null && (photoUrl as String).isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || (photoUrl as String).isEmpty)
                          ? Text(
                              employee.nombres[0],
                              style: const TextStyle(
                                color: AppColors.neutral700,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.successGreen
                              : AppColors.neutral400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Info Central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cargo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Menú de Acciones Rápidas
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'call') {
                      _makePhoneCall(employee.telefono);
                    } else if (value == 'detail') {
                      onTap();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'call',
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 20,
                            color: AppColors.neutral700,
                          ),
                          SizedBox(width: 8),
                          Text('Llamar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: AppColors.neutral700,
                          ),
                          SizedBox(width: 8),
                          Text('Ver perfil'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

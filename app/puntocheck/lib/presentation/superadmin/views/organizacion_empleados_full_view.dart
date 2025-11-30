import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrganizacionEmpleadosFullView extends ConsumerStatefulWidget {
  const OrganizacionEmpleadosFullView({super.key, required this.organization});

  final Organization? organization;

  @override
  ConsumerState<OrganizacionEmpleadosFullView> createState() =>
      _OrganizacionEmpleadosFullViewState();
}

class _OrganizacionEmpleadosFullViewState
    extends ConsumerState<OrganizacionEmpleadosFullView>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;
    if (org == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text('Organizacion no encontrada')),
      );
    }

    return Scaffold(
      appBar: _appBar(title: org.name),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.black.withValues(alpha: 0.6),
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Admins'),
              Tab(text: 'Empleados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EmployeesTab(
                  organizationId: org.id,
                  title: 'Todos los miembros',
                ),
                _EmployeesTab(
                  organizationId: org.id,
                  title: 'Administradores',
                  adminOnly: true,
                  allowSuspend: true,
                ),
                _EmployeesTab(
                  organizationId: org.id,
                  title: 'Empleados',
                  excludeAdmins: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar({String? title}) {
    return AppBar(
      title: Text(title ?? 'Empleados'),
      centerTitle: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.black),
    );
  }
}

class _EmployeesTab extends ConsumerStatefulWidget {
  const _EmployeesTab({
    required this.organizationId,
    required this.title,
    this.adminOnly = false,
    this.excludeAdmins = false,
    this.allowSuspend = false,
  });

  final String organizationId;
  final String title;
  final bool adminOnly;
  final bool excludeAdmins;
  final bool allowSuspend;

  @override
  ConsumerState<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<_EmployeesTab> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  List<Profile> _items = [];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoading || _isLoadingMore) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _items = [];
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final params = EmployeePageRequest(
        organizationId: widget.organizationId,
        page: _page,
        pageSize: 20,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        onlyAdmins: widget.adminOnly ? true : null,
        excludeAdmins: widget.excludeAdmins ? true : null,
      );
      final result =
          await ref.read(organizationEmployeesPageProvider(params).future);

      setState(() {
        if (reset) {
          _items = result.items;
        } else {
          _items = [..._items, ...result.items];
        }
        _hasMore = result.hasMore;
        _page = _page + 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando lista: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.backgroundDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, correo o código',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _load(reset: true),
          ),
          const SizedBox(height: 12),
          if (_isLoading && _items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: AppColors.black.withValues(alpha: 0.45),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay registros',
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._items.map((emp) => _EmployeeTile(
                  profile: emp,
                  showSuspend: widget.allowSuspend,
                  onToggleSuspend: () async {
                    await ref
                        .read(superAdminControllerProvider.notifier)
                        .setUserActive(
                          userId: emp.id,
                          isActive: !emp.isActive,
                        );
                    _load(reset: true);
                  },
                )),
          if (_hasMore && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: _isLoadingMore ? null : () => _load(),
                child: _isLoadingMore
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cargar más'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.profile,
    required this.showSuspend,
    required this.onToggleSuspend,
  });

  final Profile profile;
  final bool showSuspend;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
          child: Text(
            profile.initials,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(profile.fullName ?? 'Sin nombre'),
        subtitle: Text(profile.email ?? 'Sin correo'),
        trailing: showSuspend
            ? TextButton(
                onPressed: onToggleSuspend,
                child: Text(
                  profile.isActive ? 'Suspender' : 'Activar',
                  style: TextStyle(
                    color: profile.isActive
                        ? AppColors.primaryRed
                        : AppColors.successGreen,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

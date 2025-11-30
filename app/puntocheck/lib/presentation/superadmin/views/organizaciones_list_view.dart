import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card_with_stats.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_section_title.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrganizacionesListView extends ConsumerStatefulWidget {
  const OrganizacionesListView({super.key});

  @override
  ConsumerState<OrganizacionesListView> createState() =>
      _OrganizacionesListViewState();
}

class _OrganizacionesListViewState
    extends ConsumerState<OrganizacionesListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  int _selectedFilter = 0;
  int _sortOption = 0; // 0: reciente, 1: A-Z
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  List<Organization> _organizations = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(
      organizationStatusCountsProvider(_searchTermOrNull),
    );

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Organizaciones'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            onPressed: _openCreateOrganizationSheet,
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Crear organizacion',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateOrganizationSheet,
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Crear organizacion',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SaSectionTitle(title: 'Buscar'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFieldIcon(
                  controller: _searchController,
                  hintText: 'Buscar por nombre o correo...',
                  prefixIcon: Icons.search,
                ),
              ),
            ),
            const SizedBox(height: 12),
            countsAsync.when(
              data: (counts) => _buildFilters(counts),
              loading: () => _buildFilters(),
              error: (_, __) => _buildFilters(),
            ),
            const SizedBox(height: 12),
            _buildSorter(),
            const SizedBox(height: 8),
            if (_isLoading && _organizations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_organizations.isEmpty)
              _buildEmptyState()
            else
              ..._organizations.map(
                (org) => SaOrganizationCardWithStats(
                  organization: org,
                  onTap: () => context.push(
                    AppRoutes.superAdminOrganizacionDetalle,
                    extra: org,
                  ),
                ),
              ),
          if (_hasMore && _organizations.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton(
                onPressed: _isLoadingMore ? null : () => _loadPage(),
                child: _isLoadingMore
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cargar mas'),
              ),
            ),
            if (_isLoading && _organizations.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSorter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Ordenar por:',
            style: TextStyle(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sortOption,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                style: const TextStyle(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Mas recientes')),
                  DropdownMenuItem(value: 1, child: Text('Nombre A-Z')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortOption = value);
                  _loadPage(reset: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters([Map<OrgStatus, int>? counts]) {
    const filters = ['Todos', 'Activas', 'Suspendidas', 'Prueba'];
    final safeCounts = counts ??
        {
          OrgStatus.activa: 0,
          OrgStatus.suspendida: 0,
          OrgStatus.prueba: 0,
        };
    final totalCount =
        safeCounts.values.fold<int>(0, (sum, value) => sum + value);

    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          final chipCount = switch (index) {
            0 => totalCount,
            1 => safeCounts[OrgStatus.activa] ?? 0,
            2 => safeCounts[OrgStatus.suspendida] ?? 0,
            3 => safeCounts[OrgStatus.prueba] ?? 0,
            _ => 0,
          };

          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = index);
              _loadPage(reset: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 110,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          const Color(0xFFD32F2F),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primaryRed.withValues(alpha: 0.3)
                        : AppColors.black.withValues(alpha: 0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    filters[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.backgroundDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chipCount.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.9)
                          : AppColors.black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  OrgStatus? get _filterStatus => switch (_selectedFilter) {
        1 => OrgStatus.activa,
        2 => OrgStatus.suspendida,
        3 => OrgStatus.prueba,
        _ => null,
      };

  String? get _searchTermOrNull {
    final value = _searchController.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _loadPage(reset: true);
    });
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 140) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoadingMore || (_isLoading && !reset)) return;

    setState(() {
      if (reset) {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _organizations = [];
      } else {
        _isLoadingMore = true;
      }
    });

    final service = ref.read(organizationServiceProvider);
    final page = reset ? 1 : _currentPage;

    try {
      final result = await service.getOrganizationsPage(
        page: page,
        pageSize: 10,
        search: _searchTermOrNull,
        status: _filterStatus,
        sortBy: _sortOption == 1 ? 'name' : 'created_at',
        ascending: _sortOption == 1,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _organizations = result.items;
        } else {
          _organizations = [..._organizations, ...result.items];
        }
        _hasMore = result.hasMore;
        _currentPage = page + 1;
      });
      ref.invalidate(organizationStatusCountsProvider(_searchTermOrNull));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando organizaciones: $e')),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                size: 48,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron organizaciones',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajusta la busqueda o los filtros.',
              style: TextStyle(
                color: AppColors.black.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateOrganizationSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateOrganizationSheet(ref: ref),
    ).then((created) async {
      if (created == true) {
        await _loadPage(reset: true);
        ref.invalidate(
          organizationsPageProvider(defaultOrganizationsPageRequest),
        );
        ref.invalidate(superAdminStatsProvider);
      }
    });
  }
}

class _CreateOrganizationSheet extends ConsumerStatefulWidget {
  const _CreateOrganizationSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_CreateOrganizationSheet> createState() =>
      _CreateOrganizationSheetState();
}

class _CreateOrganizationSheetState
    extends ConsumerState<_CreateOrganizationSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  OrgStatus _status = OrgStatus.prueba;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvoked: (didPop) {
        if (!didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Crear nueva organizacion',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo de contacto (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<OrgStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: OrgStatus.prueba,
                  child: Text('Prueba'),
                ),
                DropdownMenuItem(
                  value: OrgStatus.activa,
                  child: Text('Activa'),
                ),
                DropdownMenuItem(
                  value: OrgStatus.suspendida,
                  child: Text('Suspendida'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: _isSubmitting ? 'Creando...' : 'Crear organizacion',
              enabled: !_isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final controller =
        widget.ref.read(superAdminControllerProvider.notifier);
    final result = await controller.createOrganization(
      name: _nameController.text.trim(),
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      status: _status,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizacion creada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la organizacion')),
      );
    }
  }
}

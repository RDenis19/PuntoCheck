import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/services/organization_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';

class OrganizacionDetalleView extends ConsumerStatefulWidget {
  const OrganizacionDetalleView({super.key, required this.organization});

  final Organization? organization;

  @override
  ConsumerState<OrganizacionDetalleView> createState() =>
      _OrganizacionDetalleViewState();
}

class _OrganizacionDetalleViewState
    extends ConsumerState<OrganizacionDetalleView> {
  late Organization _organization;
  bool _hasOrganization = false;

  final _employeeSearchController = TextEditingController();
  Timer? _employeeDebounce;
  List<Profile> _employees = [];
  bool _employeesLoading = false;
  bool _employeesLoadingMore = false;
  int _employeesPage = 1;
  String? _employeesError;
  bool _isUploadingLogo = false;
  final _imagePicker = SafeImagePicker();
  String? _localLogoUrl;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    if (org != null) {
      _organization = org;
      _hasOrganization = true;
      _employeeSearchController.addListener(_onEmployeeSearchChanged);
      _loadEmployees(reset: true);
      _recoverLostLogo();
    }
  }

  @override
  void dispose() {
    _employeeDebounce?.cancel();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasOrganization) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text('Organizacion no encontrada')),
      );
    }

    final statsAsync = ref.watch(
      organizationDashboardStatsProvider(_organization.id),
    );
    final metricsAsync = ref.watch(
      organizationMetricsProvider(_organization.id),
    );
    final planAsync = ref.watch(organizationPlanProvider(_organization.id));

    return Scaffold(
      appBar: _appBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdminManagerSheet,
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.person_add_alt_1, color: AppColors.white),
        label: const Text(
          'Crear admin',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          _Header(
            organization: _organization,
            logoUrlOverride: _localLogoUrl,
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => _StatsSection(stats: stats),
            loading: () => const _StatsSection(isLoading: true),
            error: (_, __) => const _StatsSection(hasError: true),
          ),
          metricsAsync.when(
            data: (metrics) => _HistoricMetricsSection(metrics: metrics),
            loading: () => const _HistoricMetricsSection(isLoading: true),
            error: (_, __) => const _HistoricMetricsSection(hasError: true),
          ),
          _EmployeesSection(
            employees: _employees.take(3).toList(),
            searchController: _employeeSearchController,
            isLoading: _employeesLoading,
            hasMore: _employees.length > 3,
            errorMessage: _employeesError,
            onRefresh: () => _loadEmployees(reset: true),
            onToggleAdmin: _toggleAdmin,
            onViewAll: () => context.push(
              AppRoutes.superAdminOrganizacionEmpleados,
              extra: _organization,
            ),
          ),
          _BrandingCard(organization: _organization),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
              icon: _isUploadingLogo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(
                _isUploadingLogo ? 'Subiendo logo...' : 'Cambiar logo',
              ),
            ),
          ),
          planAsync.when(
            data: (plan) => _MetaCard(
              organization: _organization,
              planSummary: plan,
            ),
            loading: () => _MetaCard(
              organization: _organization,
              isPlanLoading: true,
            ),
            error: (_, __) => _MetaCard(
              organization: _organization,
              hasPlanError: true,
            ),
          ),
          _ConfigCard(organization: _organization),
          _Actions(
            organization: _organization,
            onToggleStatus: _toggleStatus,
            onEdit: _openEditOrganizationSheet,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('Detalle de organizacion'),
      centerTitle: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.black),
    );
  }

  String? get _employeeSearchTerm {
    final value = _employeeSearchController.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onEmployeeSearchChanged() {
    _employeeDebounce?.cancel();
    _employeeDebounce = Timer(const Duration(milliseconds: 260), () {
      _loadEmployees(reset: true);
    });
  }

  Future<void> _recoverLostLogo() async {
    final file = await _imagePicker.recoverLostImage();
    if (file != null) {
      await _uploadLogoFile(file);
    }
  }

  Future<void> _loadEmployees({bool reset = false}) async {
    if (_employeesLoadingMore || (_employeesLoading && !reset)) return;

    setState(() {
      if (reset) {
        _employeesLoading = true;
        _employeesPage = 1;
        _employeesError = null;
        _employees = [];
      } else {
        _employeesLoadingMore = true;
      }
    });

    final service = ref.read(organizationServiceProvider);
    final page = reset ? 1 : _employeesPage;

    try {
      final result = await service.getEmployeesPage(
        organizationId: _organization.id,
        page: page,
        search: _employeeSearchTerm,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _employees = result.items;
        } else {
          _employees = [..._employees, ...result.items];
        }
        _employeesPage = page + 1;
        _employeesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _employeesError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando empleados: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _employeesLoading = false;
          _employeesLoadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleAdmin(Profile profile) async {
    final controller = ref.read(superAdminControllerProvider.notifier);
    final nextValue = !profile.isOrgAdmin;

    final messenger = ScaffoldMessenger.of(context);
    await controller.setOrgAdmin(
      userId: profile.id,
      isAdmin: nextValue,
      organizationId: _organization.id,
    );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nextValue
              ? 'Usuario ascendido a admin de organizacion'
              : 'Rol de admin removido',
        ),
      ),
    );
    await _loadEmployees(reset: true);
  }

  Future<void> _toggleStatus() async {
    final controller = ref.read(superAdminControllerProvider.notifier);
    final targetStatus = _organization.status == OrgStatus.suspendida
        ? OrgStatus.activa
        : OrgStatus.suspendida;
    final messenger = ScaffoldMessenger.of(context);

    final updated = await controller.setOrganizationStatus(
      _organization.id,
      targetStatus,
    );

    if (updated != null && mounted) {
      setState(() => _organization = updated);
      ref.invalidate(organizationMetricsProvider(_organization.id));
      ref.invalidate(organizationDashboardStatsProvider(_organization.id));
      ref.invalidate(organizationPlanProvider(_organization.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            targetStatus == OrgStatus.activa
                ? 'Organizacion activada'
                : 'Organizacion suspendida',
          ),
        ),
      );
    }
  }

  void _openEditOrganizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final nameController = TextEditingController(text: _organization.name);
        final emailController =
            TextEditingController(text: _organization.contactEmail ?? '');
        final brandController =
            TextEditingController(text: _organization.brandColor);
        OrgStatus status = _organization.status;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                    'Editar organizacion',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo de contacto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OrgStatus>(
                    initialValue: status,
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
                        setModalState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(
                      labelText: 'Color de marca (HEX)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: isSubmitting ? 'Guardando...' : 'Guardar cambios',
                    enabled: !isSubmitting,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre es obligatorio'),
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      setModalState(() => isSubmitting = true);
                      final controller =
                          ref.read(superAdminControllerProvider.notifier);
                      final updated = await controller.updateOrganization(
                        _organization.id,
                        {
                          'name': nameController.text.trim(),
                          'contact_email': emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          'status': status.toJson(),
                          'brand_color': brandController.text.trim().isEmpty
                              ? _organization.brandColor
                              : brandController.text.trim(),
                        },
                      );
                      setModalState(() => isSubmitting = false);

                      if (!mounted) return;
                      if (updated != null) {
                        setState(() => _organization = updated);
                        ref.invalidate(
                          organizationMetricsProvider(_organization.id),
                        );
                        ref.invalidate(
                          organizationDashboardStatsProvider(_organization.id),
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Organizacion actualizada'),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo actualizar'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadLogo() async {
    final result = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );

    if (result.permissionDenied) {
      if (mounted) {
        _showSnackBar('Permiso de fotos denegado. Habilitalo en ajustes.');
        if (result.permanentlyDenied) {
          openAppSettings();
        }
      }
      return;
    }

    if (result.errorMessage != null) {
      if (mounted) {
        _showSnackBar('No se pudo abrir la galeria: ${result.errorMessage}');
      }
      return;
    }

    final file = result.file;
    if (file == null) return;

    await _uploadLogoFile(file);
  }

  Future<void> _uploadLogoFile(File file) async {
    setState(() => _isUploadingLogo = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadOrganizationLogo(file, _organization.id);

      final updated = await ref
          .read(superAdminControllerProvider.notifier)
          .updateOrganization(_organization.id, {'logo_url': url});

      if (!mounted) return;
      if (updated != null) {
        setState(() {
          _organization = updated;
          _localLogoUrl = url;
        });
        ref.invalidate(organizationMetricsProvider(_organization.id));
        ref.invalidate(organizationDashboardStatsProvider(_organization.id));
        ref.invalidate(
          organizationsPageProvider(defaultOrganizationsPageRequest),
        );
        ref.invalidate(allOrganizationsProvider);
        _showSnackBar('Logo actualizado');
      } else {
        _showSnackBar('No se pudo actualizar el logo');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error subiendo logo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%*&?';
    final rand = Random.secure();
    return List.generate(
      14,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  void _openAdminManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final emailController = TextEditingController();
        final nameController = TextEditingController();
        final passwordController =
            TextEditingController(text: _generatePassword());
        bool isSubmitting = false;
        final params = EmployeePageRequest(
          organizationId: _organization.id,
          page: 1,
          pageSize: 50,
          onlyAdmins: true,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gestionar admins',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo del nuevo admin',
                      hintText: 'usuario@ejemplo.com',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña temporal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    text: isSubmitting ? 'Creando...' : 'Crear admin',
                    enabled: !isSubmitting,
                    onPressed: () async {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Ingresa un correo para asignar admin'),
                          ),
                        );
                        return;
                      }
                      if (passwordController.text.trim().length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La contraseña temporal debe tener al menos 8 caracteres',
                            ),
                          ),
                        );
                        return;
                      }
                      setModalState(() => isSubmitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      try {
                        await ref
                            .read(superAdminControllerProvider.notifier)
                            .createOrgAdminUser(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              fullName: nameController.text.trim().isEmpty
                                  ? null
                                  : nameController.text.trim(),
                              organizationId: _organization.id,
                            );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Admin creado. Revisa la tabla de Auth para confirmar correo.',
                            ),
                          ),
                        );
                        navigator.pop();
                        ref.invalidate(
                          organizationEmployeesPageProvider(params),
                        );
                        await _loadEmployees(reset: true);
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error creando admin: $e'),
                          ),
                        );
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final adminsAsync =
                          ref.watch(organizationEmployeesPageProvider(params));
                      return adminsAsync.when(
                        data: (page) {
                          if (page.items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.black.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_outline),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Sin admins asignados'),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: page.items.map((admin) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryRed
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    admin.initials,
                                    style: const TextStyle(
                                      color: AppColors.primaryRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(admin.fullName ?? 'Sin nombre'),
                                subtitle: Text(admin.email ?? 'Sin correo'),
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: admin.isActive
                                          ? 'Bloquear'
                                          : 'Desbloquear',
                                      icon: Icon(
                                        admin.isActive
                                            ? Icons.block
                                            : Icons.lock_open,
                                        color: admin.isActive
                                            ? AppColors.primaryRed
                                            : AppColors.successGreen,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(superAdminControllerProvider
                                                .notifier)
                                            .setUserActive(
                                              userId: admin.id,
                                              isActive: !admin.isActive,
                                            );
                                        ref.invalidate(
                                          organizationEmployeesPageProvider(
                                            params,
                                          ),
                                        );
                                        await _loadEmployees(reset: true);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Remover admin',
                                      icon: const Icon(
                                        Icons.person_remove_alt_1,
                                        color: AppColors.warningOrange,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(superAdminControllerProvider
                                                .notifier)
                                            .setOrgAdmin(
                                              userId: admin.id,
                                              isAdmin: false,
                                              organizationId: _organization.id,
                                            );
                                        ref.invalidate(
                                          organizationEmployeesPageProvider(
                                            params,
                                          ),
                                        );
                                        await _loadEmployees(reset: true);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No se pudieron cargar los admins.',
                            style: TextStyle(color: AppColors.primaryRed),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.organization,
    this.logoUrlOverride,
  });

  final Organization organization;
  final String? logoUrlOverride;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (organization.status) {
      OrgStatus.activa => AppColors.successGreen,
      OrgStatus.prueba => AppColors.warningOrange,
      OrgStatus.suspendida => AppColors.primaryRed,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            const Color(0xFFC62828), // Darker red
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _Logo(
                  organization: organization,
                  overrideLogoUrl: logoUrlOverride,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (organization.contactEmail != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              organization.contactEmail!,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'ESTADO',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        organization.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildInfoItem(
                  'CREADA',
                  _formatDate(organization.createdAt),
                  AppColors.white,
                ),
                _buildDivider(),
                _buildInfoItem(
                  'ID',
                  organization.id.length > 8
                      ? '${organization.id.substring(0, 8)}...'
                      : organization.id,
                  AppColors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.white.withValues(alpha: 0.15),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Logo extends ConsumerWidget {
  const _Logo({
    required this.organization,
    this.overrideLogoUrl,
  });

  final Organization organization;
  final String? overrideLogoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandColor = _brandColor(organization.brandColor);
    final effectiveLogo = overrideLogoUrl?.isNotEmpty == true
        ? overrideLogoUrl
        : organization.logoUrl;

    if (effectiveLogo == null || effectiveLogo.isEmpty) {
      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              brandColor.withValues(alpha: 0.2),
              brandColor.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            organization.name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ),
      );
    }

    final storage = ref.read(storageServiceProvider);
    return FutureBuilder<String>(
      future: storage.resolveOrgLogoUrl(effectiveLogo, expiresInSeconds: 3600),
      builder: (context, snapshot) {
        final url = snapshot.data ?? effectiveLogo;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                color: brandColor.withValues(alpha: 0.2),
                child: Center(
                  child: Text(
                    organization.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _brandColor(String hex) {
    final clean = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    this.stats,
    this.isLoading = false,
    this.hasError = false,
  });

  final OrganizationDashboardSnapshot? stats;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.infoBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Estadisticas de la organizacion',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasError)
                const _Warning(
                  text:
                      'No pudimos cargar estadisticas ahora. Intenta nuevamente.',
                )
              else
                Row(
                  children: [
                    _StatCard(
                      label: 'Empleados',
                      value: stats?.totalEmployees.toString() ?? '--',
                      isLoading: isLoading,
                      isDark: true,
                    ),
                    _StatCard(
                      label: 'Activos hoy',
                      value: stats?.activeToday.toString() ?? '--',
                      isLoading: isLoading,
                      isDark: true,
                    ),
                    _StatCard(
                      label: 'Asistencia',
                      value: stats != null
                          ? '${stats!.attendanceAverage}%'
                          : '--',
                      isLoading: isLoading,
                      isDark: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoricMetricsSection extends StatelessWidget {
  const _HistoricMetricsSection({
    this.metrics,
    this.isLoading = false,
    this.hasError = false,
  });

  final OrganizationMetrics? metrics;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.trending_up_outlined, color: AppColors.backgroundDark),
                  SizedBox(width: 8),
                  Text(
                    'Historico reciente',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasError)
                const _Warning(
                  text:
                      'No pudimos cargar las metricas historicas en este momento.',
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _MetricChip(
                        title: 'Atrasos',
                        primaryValue:
                            metrics?.lateLast7Days.toString() ?? '--',
                        secondaryValue:
                            '${metrics?.lateLast30Days ?? 0} en 30d',
                        isLoading: isLoading,
                        icon: Icons.alarm_on_outlined,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricChip(
                        title: 'Asistencias',
                        primaryValue:
                            metrics?.attendanceLast7Days.toString() ?? '--',
                        secondaryValue:
                            '${metrics?.attendanceLast30Days ?? 0} en 30d',
                        isLoading: isLoading,
                        icon: Icons.task_alt_outlined,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeesSection extends StatelessWidget {
  const _EmployeesSection({
    required this.employees,
    required this.searchController,
    required this.isLoading,
    required this.onRefresh,
    required this.onToggleAdmin,
    this.errorMessage,
    this.onViewAll,
    this.hasMore = false,
  });

  final List<Profile> employees;
  final TextEditingController searchController;
  final bool isLoading;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final void Function(Profile) onToggleAdmin;
  final String? errorMessage;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.backgroundDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Empleados',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  if (onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('Ver todos'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nombre o correo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (errorMessage != null)
                _Warning(text: errorMessage!)
              else if (isLoading && employees.isEmpty)
                Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (employees.isEmpty)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_off_outlined,
                        color: AppColors.black.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sin empleados registrados.',
                      style: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: employees.map(
                    (emp) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryRed.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          emp.initials,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        emp.fullName ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                      subtitle: Text(emp.email ?? 'Sin correo'),
                      trailing: emp.isOrgAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => onToggleAdmin(emp),
                    ),
                  ).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor(organization.brandColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personalizacion',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color principal: ${organization.brandColor}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        Text(
                          'Logo: ${organization.logoUrl?.isNotEmpty == true ? 'Cargado' : 'No cargado'}',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _brandColor(String hex) {
    final clean = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuracion critica de asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              _ConfigRow(
                label: 'Minutos de tolerancia',
                value: '${organization.configToleranceMinutes} minutos',
              ),
              _ConfigRow(
                label: 'Requiere foto',
                value: organization.configRequirePhoto ? 'Si' : 'No',
              ),
              _ConfigRow(
                label: 'Geolocalizacion',
                value: 'Radio ${organization.configGeofenceRadius}m',
              ),
              _ConfigRow(
                label: 'Zona horaria',
                value: organization.configTimezone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.organization,
    this.planSummary,
    this.isPlanLoading = false,
    this.hasPlanError = false,
  });

  final Organization organization;
  final PlanSummary? planSummary;
  final bool isPlanLoading;
  final bool hasPlanError;

  @override
  Widget build(BuildContext context) {
    final planName = hasPlanError
        ? 'Error cargando plan'
        : planSummary?.planName ?? 'Sin plan asignado';
    final renewal = planSummary?.renewalDate != null
        ? '${planSummary!.renewalDate!.day}/${planSummary!.renewalDate!.month}/${planSummary!.renewalDate!.year}'
        : 'No definido';
    final limitText = planSummary?.userLimit != null
        ? '${planSummary!.userLimit} usuarios'
        : 'Sin limite';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contacto y metadata',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              _ConfigRow(
                label: 'Correo',
                value: organization.contactEmail ?? 'N/A',
              ),
              _ConfigRow(label: 'ID interno', value: organization.id),
              _ConfigRow(
                label: 'Fecha de alta',
                value:
                    '${organization.createdAt.day}/${organization.createdAt.month}/${organization.createdAt.year}',
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              if (isPlanLoading)
                const Text('Cargando plan...')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfigRow(label: 'Plan activo', value: planName),
                    _ConfigRow(label: 'Limite de usuarios', value: limitText),
                    _ConfigRow(label: 'Renovacion', value: renewal),
                    _ConfigRow(
                      label: 'Usuarios activos',
                      value: planSummary?.seatsUsed?.toString() ?? 'N/A',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.organization,
    required this.onToggleStatus,
    required this.onEdit,
  });

  final Organization organization;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isSuspended = organization.status == OrgStatus.suspendida;
    final statusLabel = isSuspended ? 'Activar organizacion' : 'Suspender';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          OutlinedDarkButton(
            text: 'Editar datos basicos',
            onPressed: onEdit,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: statusLabel,
            onPressed: onToggleStatus,
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor ?? color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.isLoading = false,
    this.isDark = false,
  });

  final String label;
  final String value;
  final bool isLoading;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? AppColors.white.withValues(alpha: 0.05)
                : AppColors.black.withValues(alpha: 0.02),
            border: Border.all(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.1)
                  : AppColors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.6)
                      : AppColors.black.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              if (isLoading)
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.1)
                        : AppColors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? AppColors.white : AppColors.backgroundDark,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.title,
    required this.primaryValue,
    required this.secondaryValue,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  final String title;
  final String primaryValue;
  final String secondaryValue;
  final IconData icon;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else ...[
            Text(
              primaryValue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              secondaryValue,
              style: TextStyle(
                color: AppColors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

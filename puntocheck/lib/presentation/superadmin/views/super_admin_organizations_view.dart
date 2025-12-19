import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/pagos_suscripciones.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_create_org_view.dart';
import 'package:puntocheck/presentation/superadmin/widgets/organization_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminOrganizationsView extends ConsumerStatefulWidget {
  const SuperAdminOrganizationsView({super.key});

  @override
  ConsumerState<SuperAdminOrganizationsView> createState() =>
      _SuperAdminOrganizationsViewState();
}

enum _OrgTab { todas, activas, prueba, pausa, pagos }

class _SuperAdminOrganizationsViewState
    extends ConsumerState<SuperAdminOrganizationsView> {
  final TextEditingController _searchController = TextEditingController();
  _OrgTab _selectedTab = _OrgTab.todas;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FB,
      ), // Fondo ligeramente gris para contraste
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SuperAdminCreateOrgView()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          data: (data) {
            final planNames = {
              for (final plan in data.plans) plan.id: plan.nombre,
            };

            final search = _searchController.text.toLowerCase().trim();
            final orgs = data.organizations.where((org) {
              if (search.isEmpty) return true;
              return org.razonSocial.toLowerCase().contains(search) ||
                  org.ruc.toLowerCase().contains(search);
            }).toList();

            List<Widget> listContent;
            if (_selectedTab == _OrgTab.pagos) {
              listContent = _buildPayments(
                payments: data.pendingPayments,
                planNames: planNames,
              );
            } else if (_selectedTab == _OrgTab.todas) {
              listContent = orgs.isEmpty
                  ? const [
                      EmptyState(
                        title: 'Sin registros',
                        message: 'No hay organizaciones creadas aún.',
                        icon: Icons.business_center_outlined,
                      ),
                    ]
                  : orgs
                        .map(
                          (org) => _AnimatedPadding(
                            child: OrganizationCard(
                              organization: org,
                              planName: planNames[org.planId],
                              onTap: () => context.push(
                                '${AppRoutes.superAdminHome}/org/${org.id}',
                              ),
                            ),
                          ),
                        )
                        .toList();
            } else {
              final filtered = orgs.where((org) {
                final estado = org.estadoSuscripcion;
                switch (_selectedTab) {
                  case _OrgTab.activas:
                    return estado == EstadoSuscripcion.activo;
                  case _OrgTab.prueba:
                    return estado == EstadoSuscripcion.prueba;
                  case _OrgTab.pausa:
                    return estado == EstadoSuscripcion.vencido ||
                        estado == EstadoSuscripcion.cancelado;
                  default:
                    return true;
                }
              }).toList();

              listContent = filtered.isEmpty
                  ? [
                      const EmptyState(
                        title: 'Sin resultados',
                        message: 'No hay organizaciones en este estado.',
                        icon: Icons.filter_list_off,
                      ),
                    ]
                  : filtered
                        .map(
                          (org) => _AnimatedPadding(
                            child: OrganizationCard(
                              organization: org,
                              planName: planNames[org.planId],
                              onTap: () => context.push(
                                '${AppRoutes.superAdminHome}/org/${org.id}',
                              ),
                            ),
                          ),
                        )
                        .toList();
            }

            final pendingTotal = data.pendingPayments.fold<double>(
              0,
              (sum, p) => sum + p.monto,
            );

            return RefreshIndicator(
              onRefresh: () => ref.refresh(superAdminDashboardProvider.future),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const Text(
                    'Organizaciones',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión centralizada de clientes.',
                    style: TextStyle(
                      color: AppColors.neutral700.withOpacity(0.8),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MetricGradientCard(
                    label: 'Pagos Pendientes',
                    count: data.pendingPaymentsCount,
                    total: pendingTotal,
                  ),
                  const SizedBox(height: 24),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _TabBar(
                    selected: _selectedTab,
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                    counts: {
                      _OrgTab.todas: data.totalOrganizations,
                      _OrgTab.activas: data.activeOrganizations,
                      _OrgTab.prueba: data.trialOrganizations,
                      _OrgTab.pausa: data.inactiveOrganizations,
                      _OrgTab.pagos: data.pendingPaymentsCount,
                    },
                  ),
                  const SizedBox(height: 20),
                  ...listContent,
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error.toString()),
        ),
      ),
    );
  }

  List<Widget> _buildPayments({
    required List<PagosSuscripciones> payments,
    required Map<String, String> planNames,
  }) {
    if (payments.isEmpty) {
      return [
        const EmptyState(
          title: 'Todo al día',
          message: 'No hay pagos por validar.',
          icon: Icons.check_circle_outline,
        ),
      ];
    }

    return payments
        .map(
          (pago) => _AnimatedPadding(
            child: _PaymentCard(pago: pago, planName: planNames[pago.planId]),
          ),
        )
        .toList();
  }
}

class _MetricGradientCard extends StatelessWidget {
  const _MetricGradientCard({
    required this.label,
    required this.count,
    required this.total,
  });
  final String label;
  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0262F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count por validar • \$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o RUC...',
          hintStyle: TextStyle(color: AppColors.neutral700.withOpacity(0.5)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryRed,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onSelected,
    required this.counts,
  });
  final _OrgTab selected;
  final void Function(_OrgTab) onSelected;
  final Map<_OrgTab, int> counts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _OrgTab.values.map((tab) {
          final isSelected = selected == tab;
          final String label =
              tab.name[0].toUpperCase() + tab.name.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neutral900 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neutral900
                        : const Color(0xFFE7ECF3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      label == 'Todas'
                          ? 'Todas'
                          : label == 'Pausa'
                          ? 'En pausa'
                          : label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.neutral900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${counts[tab] ?? 0}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.neutral700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.pago, required this.planName});
  final PagosSuscripciones pago;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.primaryRed),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${pago.monto.toStringAsFixed(2)} • ${planName ?? "Plan"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'ID Org: ${pago.organizacionId}',
                  style: TextStyle(
                    color: AppColors.neutral700.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.neutral100),
        ],
      ),
    );
  }
}

class _AnimatedPadding extends StatelessWidget {
  const _AnimatedPadding({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

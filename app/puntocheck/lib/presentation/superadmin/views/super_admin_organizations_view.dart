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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SuperAdminCreateOrgView()),
          );
        },
        child: const Icon(Icons.add),
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
                        title: 'Sin organizaciones registradas',
                        message:
                            'Cuando existan organizaciones se listarán aquí.',
                        icon: Icons.business_outlined,
                      ),
                    ]
                  : orgs
                        .map(
                          (org) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                  case _OrgTab.todas:
                    return true;
                  case _OrgTab.activas:
                    return estado == EstadoSuscripcion.activo;
                  case _OrgTab.prueba:
                    return estado == EstadoSuscripcion.prueba;
                  case _OrgTab.pausa:
                    return estado == EstadoSuscripcion.vencido ||
                        estado == EstadoSuscripcion.cancelado;
                  case _OrgTab.pagos:
                    return false;
                }
              }).toList();

              listContent = filtered.isEmpty
                  ? [
                      const EmptyState(
                        title: 'Sin organizaciones en esta seccion',
                        message:
                            'No se encontraron organizaciones con este estado.',
                        icon: Icons.business_outlined,
                      ),
                    ]
                  : filtered
                        .map(
                          (org) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Organizaciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestiona todas tus organizaciones en un solo lugar.',
                    style: TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 14),
                  _MetricCard(
                    label: 'Pagos pendientes',
                    value: data.pendingPaymentsCount,
                    amount: pendingTotal,
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(controller: _searchController),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  ...listContent,
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: AppColors.neutral700,
                  ),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar organizaciones'),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref.refresh(superAdminDashboardProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPayments({
    required List<PagosSuscripciones> payments,
    required Map<String, String> planNames,
  }) {
    if (payments.isEmpty) {
      return const [
        EmptyState(
          title: 'Sin pagos pendientes',
          message: 'Cuando existan pagos por validar se mostraran aqui.',
          icon: Icons.receipt_long_outlined,
        ),
      ];
    }

    return payments
        .map(
          (pago) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PaymentCard(pago: pago, planName: planNames[pago.planId]),
          ),
        )
        .toList();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.amount,
  });

  final String label;
  final int value;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRedDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value pagos | \$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar organizacion...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: (_) => (context as Element).markNeedsBuild(),
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
  final void Function(_OrgTab tab) onSelected;
  final Map<_OrgTab, int> counts;

  @override
  Widget build(BuildContext context) {
    Widget chip({required _OrgTab tab, required String label}) {
      final isSelected = tab == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${counts[tab] ?? 0}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.neutral700.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(tab),
          selectedColor: AppColors.neutral900,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.neutral900
                  : const Color(0xFFE7ECF3),
            ),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(tab: _OrgTab.todas, label: 'Todas'),
          chip(tab: _OrgTab.activas, label: 'Activas'),
          chip(tab: _OrgTab.prueba, label: 'En prueba'),
          chip(tab: _OrgTab.pausa, label: 'En pausa'),
          chip(tab: _OrgTab.pagos, label: 'Pagos pendientes'),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRedDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${pago.monto.toStringAsFixed(2)} | ${planName ?? 'Plan'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Org: ${pago.organizacionId} | Ref: ${pago.referenciaBancaria ?? 'Sin referencia'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (pago.creadoEn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${pago.creadoEn!.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

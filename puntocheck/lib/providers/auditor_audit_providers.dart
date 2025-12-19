import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auditoria_log.dart';
import '../models/enums.dart';
import 'auditor_providers.dart';

class AuditorAuditLogFilter {
  final DateTimeRange? dateRange;
  final String actionQuery;
  final String? table;
  final String? actorId;
  final String? branchId;
  final RolUsuario? actorRole;

  const AuditorAuditLogFilter({
    this.dateRange,
    this.actionQuery = '',
    this.table,
    this.actorId,
    this.branchId,
    this.actorRole,
  });

  AuditorAuditLogFilter copyWith({
    DateTimeRange? dateRange,
    bool dateRangeToNull = false,
    String? actionQuery,
    String? table,
    bool tableToNull = false,
    String? actorId,
    bool actorIdToNull = false,
    String? branchId,
    bool branchIdToNull = false,
    RolUsuario? actorRole,
    bool actorRoleToNull = false,
  }) {
    return AuditorAuditLogFilter(
      dateRange: dateRangeToNull ? null : (dateRange ?? this.dateRange),
      actionQuery: actionQuery ?? this.actionQuery,
      table: tableToNull ? null : (table ?? this.table),
      actorId: actorIdToNull ? null : (actorId ?? this.actorId),
      branchId: branchIdToNull ? null : (branchId ?? this.branchId),
      actorRole: actorRoleToNull ? null : (actorRole ?? this.actorRole),
    );
  }

  static AuditorAuditLogFilter initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 6),
    );
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return AuditorAuditLogFilter(dateRange: DateTimeRange(start: start, end: end));
  }

  @override
  bool operator ==(Object other) {
    return other is AuditorAuditLogFilter &&
        other.actionQuery == actionQuery &&
        other.table == table &&
        other.actorId == actorId &&
        other.branchId == branchId &&
        other.actorRole == actorRole &&
        other.dateRange?.start == dateRange?.start &&
        other.dateRange?.end == dateRange?.end;
  }

  @override
  int get hashCode =>
      Object.hash(dateRange?.start, dateRange?.end, actionQuery, table, actorId, branchId, actorRole);
}

final auditorAuditLogFilterProvider = StateProvider<AuditorAuditLogFilter>((ref) {
  return AuditorAuditLogFilter.initial();
});

final auditorAuditLogProvider =
    FutureProvider.autoDispose<List<AuditoriaLog>>((ref) async {
  final filter = ref.watch(auditorAuditLogFilterProvider);
  final orgId = await requireAuditorOrgId(ref);

  DateTime? start = filter.dateRange?.start;
  DateTime? end = filter.dateRange?.end;
  if (start != null) start = DateTime(start.year, start.month, start.day);
  if (end != null) end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

  final list = await ref.read(auditorServiceProvider).getAuditLog(
        orgId: orgId,
        startDate: start,
        endDate: end,
        actionQuery: filter.actionQuery,
        table: filter.table,
        actorId: filter.actorId,
        branchId: filter.branchId,
        limit: 300,
      );

  if (filter.actorRole == null) return list;
  return list.where((l) => l.actorRol == filter.actorRole!.value).toList();
});

/// Logs recientes (para dashboard) sin filtros.
final auditorAuditLogRecentProvider =
    FutureProvider.autoDispose<List<AuditoriaLog>>((ref) async {
  final orgId = await requireAuditorOrgId(ref);
  return ref.read(auditorServiceProvider).getAuditLog(
        orgId: orgId,
        limit: 3,
      );
});

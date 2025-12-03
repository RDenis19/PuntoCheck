import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/organization_model.dart';
import '../models/organization_plan.dart';
import '../models/profile_model.dart';

/// Contenedor generico para paginaciones server side.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length + ((page - 1) * pageSize) < total;
}

/// Resumen del plan de una organizacion.
class PlanSummary {
  const PlanSummary({
    required this.planName,
    this.userLimit,
    this.renewalDate,
    this.status = 'unknown',
    this.seatsUsed,
  });

  final String planName;
  final int? userLimit;
  final DateTime? renewalDate;
  final String status;
  final int? seatsUsed;

  bool get isActive => status == 'active' || status == 'trialing';
}

/// Metricas historicas de asistencia para una organizacion.
class OrganizationMetrics {
  const OrganizationMetrics({
    required this.totalEmployees,
    required this.activeShifts,
    required this.lateLast7Days,
    required this.lateLast30Days,
    required this.attendanceLast7Days,
    required this.attendanceLast30Days,
  });

  final int totalEmployees;
  final int activeShifts;
  final int lateLast7Days;
  final int lateLast30Days;
  final int attendanceLast7Days;
  final int attendanceLast30Days;
}

/// Servicio centralizado de operaciones de organizaciones
/// (incluye flujos de super admin y admin).
class OrganizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la organizacion del usuario actual (join logico profile -> org).
  Future<Organization?> getMyOrganization() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profileData = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      final orgId = profileData?['organization_id'];
      if (orgId == null) return null;

      final orgData = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();

      return Organization.fromJson(orgData);
    } catch (e) {
      print('Error obteniendo organizacion: $e');
      return null;
    }
  }

  /// Crea una organizacion y devuelve el registro listo para usar.
  Future<Organization> createOrganization({
    required String name,
    String? contactEmail,
    OrgStatus status = OrgStatus.prueba,
    String brandColor = '#EB283D',
    String? logoUrl,
    int toleranceMinutes = 5,
    bool requirePhoto = true,
    int geofenceRadius = 50,
    String timezone = 'America/Guayaquil',
  }) async {
    final payload = {
      'name': name,
      'contact_email': contactEmail,
      'status': status.toJson(),
      'brand_color': brandColor,
      'logo_url': logoUrl,
      'config_tolerance_minutes': toleranceMinutes,
      'config_require_photo': requirePhoto,
      'config_geofence_radius': geofenceRadius,
      'config_timezone': timezone,
    };

    try {
      final data = await _supabase
          .from('organizations')
          .insert(payload)
          .select()
          .single();
      return Organization.fromJson(data);
    } catch (e) {
      throw Exception('No se pudo crear la organizacion: $e');
    }
  }

  /// Actualiza parcialmente una organizacion (omite valores nulos).
  Future<Organization> updateOrganization(
    String organizationId,
    Map<String, dynamic> updates,
  ) async {
    final sanitized = Map<String, dynamic>.from(updates)
      ..removeWhere((_, value) => value == null);

    if (sanitized.isEmpty) {
      throw Exception('No hay cambios para aplicar.');
    }

    try {
      final data = await _supabase
          .from('organizations')
          .update(sanitized)
          .eq('id', organizationId)
          .select()
          .single();
      return Organization.fromJson(data);
    } catch (e) {
      throw Exception('Error actualizando organizacion: $e');
    }
  }

  /// Actualiza configuracion sensible desde panel de admin (sin retorno).
  Future<void> updateConfig(String orgId, Map<String, dynamic> updates) async {
    final sanitized = Map<String, dynamic>.from(updates)
      ..removeWhere((_, value) => value == null);
    if (sanitized.isEmpty) return;

    try {
      await _supabase
          .from('organizations')
          .update(sanitized)
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error actualizando configuracion: $e');
    }
  }

  /// Cambia el estado (activa/suspendida/prueba).
  Future<Organization> setOrganizationStatus(
    String organizationId,
    OrgStatus status,
  ) async {
    return updateOrganization(organizationId, {'status': status.toJson()});
  }

  Future<Organization> suspendOrganization(String organizationId) =>
      setOrganizationStatus(organizationId, OrgStatus.suspendida);

  Future<Organization> activateOrganization(String organizationId) =>
      setOrganizationStatus(organizationId, OrgStatus.activa);

  /// Obtiene todas las organizaciones sin paginacion (uso puntual).
  Future<List<Organization>> getAllOrganizations() async {
    try {
      final data = await _supabase
          .from('organizations')
          .select()
          .order('created_at', ascending: false);

      return (data as List).map((e) => Organization.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando organizaciones: $e');
    }
  }

  /// Paginacion y busqueda server side de organizaciones.
  Future<PaginatedResult<Organization>> getOrganizationsPage({
    required int page,
    int pageSize = 12,
    String? search,
    OrgStatus? status,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final from = (safePage - 1) * pageSize;
    final to = from + pageSize - 1;

    try {
      final countBuilder = _applyOrganizationFilters(
        _supabase.from('organizations').select(),
        search: search,
        status: status,
      );
      final countResponse = await countBuilder.count();
      final total = countResponse.count;

      final rows = await _applyOrganizationFilters(
        _supabase.from('organizations').select(),
        search: search,
        status: status,
      )
          .order(sortBy, ascending: ascending)
          .range(from, to);

      final items =
          (rows as List).map((row) => Organization.fromJson(row)).toList();

      return PaginatedResult(
        items: items,
        total: total,
        page: safePage,
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception('Error paginando organizaciones: $e');
    }
  }

  /// Cantidad de organizaciones por estado (para filtros/chips).
  Future<Map<OrgStatus, int>> getOrganizationStatusCounts({
    String? search,
  }) async {
    final result = <OrgStatus, int>{};
    for (final status in OrgStatus.values) {
      final response = await _applyOrganizationFilters(
        _supabase.from('organizations').select(),
        search: search,
        status: status,
      ).count();
      result[status] = response.count;
    }
    return result;
  }

  /// Empleados de una organizacion sin paginar (admin).
  Future<List<Profile>> getEmployeesByOrg(String organizationId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando empleados: $e');
    }
  }

  /// Paginacion server side de empleados por organizacion.
  Future<PaginatedResult<Profile>> getEmployeesPage({
    required String organizationId,
    required int page,
    int pageSize = 20,
    String? search,
    bool? onlyAdmins,
    bool? excludeAdmins,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final from = (safePage - 1) * pageSize;
    final to = from + pageSize - 1;

    try {
      final totalResponse = await _applyEmployeeFilters(
        _supabase
            .from('profiles')
            .select()
            .eq('organization_id', organizationId),
        search: search,
        onlyAdmins: onlyAdmins,
        excludeAdmins: excludeAdmins,
      ).count();

      final total = totalResponse.count;

      final baseQuery = _applyEmployeeFilters(
        _supabase
            .from('profiles')
            .select()
            .eq('organization_id', organizationId),
        search: search,
        onlyAdmins: onlyAdmins,
        excludeAdmins: excludeAdmins,
      );

      final rows = await baseQuery
          .order('created_at', ascending: false)
          .range(from, to);

      final items =
          (rows as List).map((row) => Profile.fromJson(row)).toList();

      return PaginatedResult(
        items: items,
        total: total,
        page: safePage,
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception('Error paginando empleados: $e');
    }
  }

  /// Metricas historicas (asistencias/atrasos) para dashboards.
  Future<OrganizationMetrics> getOrganizationMetrics(String organizationId) async {
    try {
      final totalEmployeesResponse = await _supabase
          .from('profiles')
          .select()
          .eq('organization_id', organizationId)
          .count();
      final totalEmployees = totalEmployeesResponse.count;

      final activeShiftsResponse = await _supabase
          .from('work_shifts')
          .select()
          .eq('organization_id', organizationId)
          .isFilter('check_out_time', null)
          .count();
      final activeShifts = activeShiftsResponse.count;

      final now = DateTime.now();
      final start7 = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final start30 = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));

      final late7 = await _countShifts(
        organizationId: organizationId,
        from: start7,
        status: AttendanceStatus.tardanza.toJson(),
      );
      final late30 = await _countShifts(
        organizationId: organizationId,
        from: start30,
        status: AttendanceStatus.tardanza.toJson(),
      );
      final attendance7 = await _countShifts(
        organizationId: organizationId,
        from: start7,
      );
      final attendance30 = await _countShifts(
        organizationId: organizationId,
        from: start30,
      );

      return OrganizationMetrics(
        totalEmployees: totalEmployees,
        activeShifts: activeShifts,
        lateLast7Days: late7,
        lateLast30Days: late30,
        attendanceLast7Days: attendance7,
        attendanceLast30Days: attendance30,
      );
    } catch (e) {
      throw Exception('Error obteniendo metricas: $e');
    }
  }

  /// Estadisticas basicas para dashboard de admin (organizacion actual).
  Future<Map<String, dynamic>> getAdminDashboardStats(String organizationId) async {
    try {
      final totalEmployeesResponse = await _supabase
          .from('profiles')
          .select()
          .eq('organization_id', organizationId)
          .count();
      final totalEmployees = totalEmployeesResponse.count;

      final activeShiftsResponse = await _supabase
          .from('work_shifts')
          .select('id, user_id, profiles!inner(organization_id)')
          .eq('profiles.organization_id', organizationId)
          .filter('check_out_time', 'is', null);

      final activeShifts = (activeShiftsResponse as List).length;

      return {
        'employees': totalEmployees,
        'active_shifts': activeShifts,
        'late_arrivals': 0, // TODO: implementar logica de atrasos
      };
    } catch (e) {
      throw Exception('Error obteniendo estadisticas de admin: $e');
    }
  }

  /// Estadisticas globales para panel de super admin.
  Future<Map<String, int>> getSuperAdminStats() async {
    try {
      final orgsResponse =
          await _supabase.from('organizations').select().count();
      final orgsCount = orgsResponse.count;

      final usersResponse =
          await _supabase.from('profiles').select().count();
      final usersCount = usersResponse.count;

      int activePlans = orgsCount;
      try {
        final plansResponse = await _supabase
            .from('organization_plans')
            .select()
            .neq('status', 'canceled')
            .count();
        activePlans = plansResponse.count;
      } catch (_) {
        // Si no existe la tabla, usamos numero de organizaciones como aproximacion.
      }

      return {
        'organizations': orgsCount,
        'users': usersCount,
        'active_plans': activePlans,
      };
    } catch (e) {
      throw Exception('Error obteniendo estadisticas globales: $e');
    }
  }

  /// Asigna o remueve rol de admin de organizacion a un usuario.
  Future<void> setOrgAdmin({
    required String userId,
    required bool isAdmin,
    String? organizationId,
  }) async {
    final updates = <String, dynamic>{
      'is_org_admin': isAdmin,
      if (organizationId != null) 'organization_id': organizationId,
    };

    try {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('No se pudo actualizar rol de admin: $e');
    }
  }

  /// Asigna rol de admin por email (requiere que exista el perfil).
  Future<void> setOrgAdminByEmail({
    required String email,
    required String organizationId,
    bool isAdmin = true,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'is_org_admin': isAdmin,
            'organization_id': organizationId,
          })
          .eq('email', email);
    } catch (e) {
      throw Exception('No se pudo actualizar rol por email: $e');
    }
  }

  /// Activa o bloquea un usuario.
  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      throw Exception('No se pudo actualizar estado del usuario: $e');
    }
  }

  /// Trae el plan activo, limite de usuarios y fecha de renovacion.
  Future<PlanSummary> getPlanSummary(String organizationId) async {
    int? seatsUsed;
    try {
      final seatsResponse = await _supabase
          .from('profiles')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .count();
      seatsUsed = seatsResponse.count;
    } catch (_) {
      seatsUsed = null;
    }

    try {
      final data = await _supabase
          .from('organization_plans')
          .select()
          .eq('organization_id', organizationId)
          .order('renews_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final plan =
          data != null ? OrganizationPlan.fromJson(data) : null;

      if (plan == null) {
        return PlanSummary(
          planName: 'Sin plan asignado',
          userLimit: null,
          renewalDate: null,
          status: 'missing',
          seatsUsed: seatsUsed,
        );
      }

      return PlanSummary(
        planName: plan.planName.isNotEmpty ? plan.planName : 'Personalizado',
        userLimit: plan.userLimit,
        renewalDate: plan.renewsAt,
        status: plan.status.isNotEmpty ? plan.status : 'active',
        seatsUsed: seatsUsed,
      );
    } catch (_) {
      return PlanSummary(
        planName: 'No disponible',
        userLimit: null,
        renewalDate: null,
        status: 'error',
        seatsUsed: seatsUsed,
      );
    }
  }

  /// Crea un usuario marcado como admin de la organizacion.
  Future<AuthResponse> createOrgAdminUser({
    required String email,
    required String password,
    String? fullName,
    required String organizationId,
  }) async {
    try {
      AuthResponse? response;
      try {
        final adminRes = await _supabase.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
            userMetadata: {
              'full_name': fullName,
              'organization_id': organizationId,
              'is_org_admin': true,
              'is_active': true,
            },
          ),
        );
        response = AuthResponse(session: null, user: adminRes.user);
      } on AuthException {
        // Fallback para entornos sin service role: usa signUp (cuidado,
        // esto cambia la sesion actual; se recomienda usar service role).
        response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'organization_id': organizationId,
            'is_org_admin': true,
            'is_active': true,
          },
        );
      }

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('El usuario no se pudo crear (sin ID devuelto).');
      }

      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'organization_id': organizationId,
        'is_org_admin': true,
        'is_active': true,
      });

      await setOrgAdmin(
        userId: userId,
        isAdmin: true,
        organizationId: organizationId,
      );

      return AuthResponse(
        session: null,
        user: response.user,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo crear el admin: $e');
    }
  }

  /// Crea un usuario con rol de empleado (sin permisos de admin).
  Future<AuthResponse> createEmployeeUser({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    required String organizationId,
  }) async {
    AuthResponse? response;
    try {
      try {
        final adminRes = await _supabase.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
            userMetadata: {
              'full_name': fullName,
              'phone': phone,
              'organization_id': organizationId,
              'is_org_admin': false,
              'is_active': true,
            },
          ),
        );
        response = AuthResponse(session: null, user: adminRes.user);
      } on AuthException {
        // Fallback a signUp p��blico si no hay service key.
      }

      response ??= await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'organization_id': organizationId,
          'is_org_admin': false,
          'is_active': true,
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('El usuario no se pudo crear (sin ID devuelto).');
      }

      // Intentamos garantizar el profile; si RLS lo bloquea pero el trigger ya lo cre�, ignoramos.
      try {
        await _supabase.from('profiles').upsert({
          'id': userId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'organization_id': organizationId,
          'is_org_admin': false,
          'is_active': true,
          'job_title': 'Empleado',
        });
      } catch (_) {
        // Si RLS bloquea el upsert pero ya existe por trigger, seguimos.
      }

      return AuthResponse(session: null, user: response.user);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      // Si el usuario ya fue creado pero el upsert fall� por RLS, devolvemos el user.
      if (response?.user != null) {
        return AuthResponse(session: null, user: response!.user);
      }
      throw Exception('No se pudo crear el empleado: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PostgrestFilterBuilder<T> _applyOrganizationFilters<T>(
    PostgrestFilterBuilder<T> query, {
    String? search,
    OrgStatus? status,
  }) {
    var builder = query;
    final trimmed = search?.trim();

    if (trimmed != null && trimmed.isNotEmpty) {
      final pattern = '%$trimmed%';
      builder = builder.or(
        'name.ilike.$pattern,contact_email.ilike.$pattern',
      );
    }

    if (status != null) {
      builder = builder.eq('status', status.toJson());
    }

    return builder;
  }

  PostgrestFilterBuilder<T> _applyEmployeeFilters<T>(
    PostgrestFilterBuilder<T> query, {
    String? search,
    bool? onlyAdmins,
    bool? excludeAdmins,
  }) {
    var builder = query;
    final trimmed = search?.trim();

    if (trimmed != null && trimmed.isNotEmpty) {
      final pattern = '%$trimmed%';
      builder = builder.or(
        'full_name.ilike.$pattern,email.ilike.$pattern,employee_code.ilike.$pattern',
      );
    }

    if (onlyAdmins == true) {
      builder = builder.eq('is_org_admin', true);
    }
    if (excludeAdmins == true) {
      builder = builder.eq('is_org_admin', false);
    }

    return builder;
  }

  Future<int> _countShifts({
    required String organizationId,
    required DateTime from,
    String? status,
  }) async {
    final fromDate = from.toIso8601String().split('T').first;
    var query = _supabase
        .from('work_shifts')
        .select()
        .eq('organization_id', organizationId)
        .gte('date', fromDate);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.count();
    return response.count;
  }
}

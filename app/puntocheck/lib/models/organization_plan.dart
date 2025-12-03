/// Modelo para la tabla `organization_plans`.
class OrganizationPlan {
  final String id;
  final String organizationId;
  final String planName;
  final int? userLimit;
  final DateTime? renewsAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrganizationPlan({
    required this.id,
    required this.organizationId,
    required this.planName,
    this.userLimit,
    this.renewsAt,
    this.status = 'trialing',
    this.createdAt,
    this.updatedAt,
  });

  OrganizationPlan copyWith({
    String? id,
    String? organizationId,
    String? planName,
    int? userLimit,
    DateTime? renewsAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationPlan(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      planName: planName ?? this.planName,
      userLimit: userLimit ?? this.userLimit,
      renewsAt: renewsAt ?? this.renewsAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrganizationPlan.fromJson(Map<String, dynamic> json) {
    return OrganizationPlan(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      planName: json['plan_name'] as String,
      userLimit: json['user_limit'] as int?,
      renewsAt: json['renews_at'] != null
          ? DateTime.tryParse(json['renews_at'] as String)
          : null,
      status: json['status'] as String? ?? 'trialing',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'plan_name': planName,
      'user_limit': userLimit,
      'renews_at': renewsAt?.toIso8601String(),
      'status': status,
    };
  }
}

/// Modelo tipado para la tabla `global_settings` (fila única).
class GlobalSettings {
  final String id;
  final int toleranceMinutes;
  final int geofenceRadius;
  final bool requirePhoto;
  final String senderEmail;
  final int alertThreshold;
  final String? adminAutoDomain;
  final int trialMaxOrgs;
  final int trialDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GlobalSettings({
    this.id = 'default',
    this.toleranceMinutes = 5,
    this.geofenceRadius = 50,
    this.requirePhoto = true,
    this.senderEmail = 'noreply@puntocheck.com',
    this.alertThreshold = 3,
    this.adminAutoDomain,
    this.trialMaxOrgs = 3,
    this.trialDays = 14,
    this.createdAt,
    this.updatedAt,
  });

  GlobalSettings copyWith({
    String? id,
    int? toleranceMinutes,
    int? geofenceRadius,
    bool? requirePhoto,
    String? senderEmail,
    int? alertThreshold,
    String? adminAutoDomain,
    int? trialMaxOrgs,
    int? trialDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalSettings(
      id: id ?? this.id,
      toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      requirePhoto: requirePhoto ?? this.requirePhoto,
      senderEmail: senderEmail ?? this.senderEmail,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      adminAutoDomain: adminAutoDomain ?? this.adminAutoDomain,
      trialMaxOrgs: trialMaxOrgs ?? this.trialMaxOrgs,
      trialDays: trialDays ?? this.trialDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
    return GlobalSettings(
      id: json['id'] as String? ?? 'default',
      toleranceMinutes: json['tolerance_minutes'] as int? ?? 5,
      geofenceRadius: json['geofence_radius'] as int? ?? 50,
      requirePhoto: json['require_photo'] as bool? ?? true,
      senderEmail: json['sender_email'] as String? ?? 'noreply@puntocheck.com',
      alertThreshold: json['alert_threshold'] as int? ?? 3,
      adminAutoDomain: json['admin_auto_domain'] as String?,
      trialMaxOrgs: json['trial_max_orgs'] as int? ?? 3,
      trialDays: json['trial_days'] as int? ?? 14,
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
      'tolerance_minutes': toleranceMinutes,
      'geofence_radius': geofenceRadius,
      'require_photo': requirePhoto,
      'sender_email': senderEmail,
      'alert_threshold': alertThreshold,
      'admin_auto_domain': adminAutoDomain,
      'trial_max_orgs': trialMaxOrgs,
      'trial_days': trialDays,
    };
  }

  static GlobalSettings defaults() => const GlobalSettings();
}

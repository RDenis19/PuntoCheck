import 'enums.dart';

class Organization {
  final String id;
  final String name;
  final String? contactEmail;
  final OrgStatus status;
  
  // Branding
  final String brandColor;
  final String? logoUrl;

  // Configuración Técnica
  final int configToleranceMinutes;
  final bool configRequirePhoto;
  final int configGeofenceRadius;
  final String configTimezone;
  
  final DateTime createdAt;

  const Organization({
    required this.id,
    required this.name,
    this.contactEmail,
    required this.status,
    this.brandColor = '#EB283D',
    this.logoUrl,
    this.configToleranceMinutes = 5,
    this.configRequirePhoto = true,
    this.configGeofenceRadius = 50,
    this.configTimezone = 'America/Guayaquil',
    required this.createdAt,
  });

  Organization copyWith({
    String? name,
    String? contactEmail,
    OrgStatus? status,
    String? brandColor,
    String? logoUrl,
    int? configToleranceMinutes,
    bool? configRequirePhoto,
    int? configGeofenceRadius,
    String? configTimezone,
  }) {
    return Organization(
      id: this.id, // ID no debe cambiar
      name: name ?? this.name,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      brandColor: brandColor ?? this.brandColor,
      logoUrl: logoUrl ?? this.logoUrl,
      configToleranceMinutes: configToleranceMinutes ?? this.configToleranceMinutes,
      configRequirePhoto: configRequirePhoto ?? this.configRequirePhoto,
      configGeofenceRadius: configGeofenceRadius ?? this.configGeofenceRadius,
      configTimezone: configTimezone ?? this.configTimezone,
      createdAt: this.createdAt,
    );
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      contactEmail: json['contact_email'] as String?,
      status: OrgStatus.fromJson(json['status'] as String),
      brandColor: json['brand_color'] as String? ?? '#EB283D',
      logoUrl: json['logo_url'] as String?,
      configToleranceMinutes: json['config_tolerance_minutes'] as int? ?? 5,
      configRequirePhoto: json['config_require_photo'] as bool? ?? true,
      configGeofenceRadius: json['config_geofence_radius'] as int? ?? 50,
      configTimezone: json['config_timezone'] as String? ?? 'America/Guayaquil',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id usualmente no se envía en updates, pero lo dejo por consistencia
      'name': name,
      'contact_email': contactEmail,
      'status': status.toJson(),
      'brand_color': brandColor,
      'logo_url': logoUrl,
      'config_tolerance_minutes': configToleranceMinutes,
      'config_require_photo': configRequirePhoto,
      'config_geofence_radius': configGeofenceRadius,
      'config_timezone': configTimezone,
    };
  }
}
class Profile {
  final String id;
  final String? organizationId;
  final String? email;
  final String? fullName;
  final String? employeeCode;
  final String? phone;
  final String? avatarUrl;
  final String jobTitle;
  
  // Roles
  final bool isSuperAdmin;
  final bool isOrgAdmin;
  final bool isActive;

  const Profile({
    required this.id,
    this.organizationId,
    this.email,
    this.fullName,
    this.employeeCode,
    this.phone,
    this.avatarUrl,
    this.jobTitle = 'Empleado',
    this.isSuperAdmin = false,
    this.isOrgAdmin = false,
    this.isActive = true,
  });

  Profile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? jobTitle,
    bool? isActive,
  }) {
    return Profile(
      id: this.id,
      organizationId: this.organizationId,
      email: this.email,
      employeeCode: this.employeeCode, // Código raramente cambia
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      jobTitle: jobTitle ?? this.jobTitle,
      isSuperAdmin: this.isSuperAdmin,
      isOrgAdmin: this.isOrgAdmin,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      jobTitle: json['job_title'] as String? ?? 'Empleado',
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      isOrgAdmin: json['is_org_admin'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'job_title': jobTitle,
      // Roles y IDs suelen ser read-only desde el cliente o manejados por Admin
    };
  }
  
  // Helper para UI
  String get initials {
    if (fullName == null || fullName!.isEmpty) return 'NA';
    final names = fullName!.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }
}
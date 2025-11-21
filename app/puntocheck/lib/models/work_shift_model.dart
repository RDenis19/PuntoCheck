import 'enums.dart';
import 'geo_location.dart';

class WorkShift {
  final String id;
  final String organizationId;
  final String userId;
  final DateTime date;
  
  // Check-In
  final DateTime checkInTime;
  final GeoLocation? checkInLocation;
  final String? checkInPhotoUrl;
  final String? checkInAddress;

  // Check-Out (Nullables porque pueden no haber salido aún)
  final DateTime? checkOutTime;
  final GeoLocation? checkOutLocation;
  final String? checkOutPhotoUrl;
  final String? checkOutAddress;

  // Generados / Calculados
  final int? durationMinutes; // Generado en DB
  final AttendanceStatus status;

  const WorkShift({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.date,
    required this.checkInTime,
    this.checkInLocation,
    this.checkInPhotoUrl,
    this.checkInAddress,
    this.checkOutTime,
    this.checkOutLocation,
    this.checkOutPhotoUrl,
    this.checkOutAddress,
    this.durationMinutes,
    this.status = AttendanceStatus.puntual,
  });

  bool get isActive => checkOutTime == null;

  WorkShift copyWith({
    DateTime? checkOutTime,
    GeoLocation? checkOutLocation,
    String? checkOutPhotoUrl,
    String? checkOutAddress,
  }) {
    return WorkShift(
      id: this.id,
      organizationId: this.organizationId,
      userId: this.userId,
      date: this.date,
      checkInTime: this.checkInTime,
      checkInLocation: this.checkInLocation,
      checkInPhotoUrl: this.checkInPhotoUrl,
      checkInAddress: this.checkInAddress,
      // Solo permitimos editar salida usualmente desde la app
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      checkOutAddress: checkOutAddress ?? this.checkOutAddress,
      durationMinutes: this.durationMinutes,
      status: this.status,
    );
  }

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      
      checkInTime: DateTime.parse(json['check_in_time'] as String).toLocal(), // Convertir a hora local
      checkInLocation: json['check_in_location'] != null 
          ? GeoLocation.fromJson(json['check_in_location']) 
          : null,
      checkInPhotoUrl: json['check_in_photo_url'] as String?,
      checkInAddress: json['check_in_address'] as String?,
      
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time'] as String).toLocal() 
          : null,
      checkOutLocation: json['check_out_location'] != null 
          ? GeoLocation.fromJson(json['check_out_location']) 
          : null,
      checkOutPhotoUrl: json['check_out_photo_url'] as String?,
      checkOutAddress: json['check_out_address'] as String?,
      
      durationMinutes: json['duration_minutes'] as int?,
      status: AttendanceStatus.fromJson(json['status'] as String),
    );
  }

  // ToJson para Insertar (Entrada)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      // 'organization_id': No es necesario si el Trigger lo pone, pero mejor enviarlo si lo tienes
      'check_in_location': checkInLocation?.toJson(), // PostGIS GeoJSON
      'check_in_photo_url': checkInPhotoUrl,
      'check_in_address': checkInAddress,
      // Date y CheckInTime son Default NOW() en DB, no hace falta enviar
    };
  }

  // ToJson para Actualizar (Salida)
  Map<String, dynamic> toUpdateJson() {
    return {
      'check_out_time': DateTime.now().toIso8601String(),
      'check_out_location': checkOutLocation?.toJson(),
      'check_out_photo_url': checkOutPhotoUrl,
      'check_out_address': checkOutAddress,
    };
  }
}
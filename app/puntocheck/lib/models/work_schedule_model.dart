import 'enums.dart';

class WorkSchedule {
  final String id;
  final String organizationId;
  final String? userId;
  final int dayOfWeek; // 0-6
  final String startTime; // "08:00:00"
  final String endTime;   // "17:00:00"
  final ShiftCategory type;

  const WorkSchedule({
    required this.id,
    required this.organizationId,
    this.userId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.type = ShiftCategory.completa,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String?,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      type: ShiftCategory.fromJson(json['type'] as String),
    );
  }
  
  // Helper para convertir string "08:00:00" a DateTime hoy
  DateTime get startDateTime {
    final now = DateTime.now();
    final parts = startTime.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
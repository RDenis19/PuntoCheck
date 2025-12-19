import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/employee/widgets/attendance/employee_attendance_style.dart';
import 'package:puntocheck/services/attendance_summary_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeAttendanceSummaryHeader extends StatelessWidget {
  const EmployeeAttendanceSummaryHeader({
    super.key,
    required this.today,
    required this.month,
  });

  final AttendanceDaySummary? today;
  final AttendanceMonthSummary month;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Hoy',
            value: today == null ? '—' : _fmtDuration(today!.workedNet),
            hint: today == null ? 'Sin registros' : 'Trabajadas (estimado)',
            icon: Icons.today_outlined,
            color: AppColors.infoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Este mes',
            value: _fmtDuration(month.workedNet),
            hint: '${month.daysWithRecords} días • ${month.daysIncomplete} incompletos',
            icon: Icons.calendar_month_outlined,
            color: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}

class EmployeeAttendanceDayCard extends StatefulWidget {
  const EmployeeAttendanceDayCard({
    super.key,
    required this.day,
    required this.dateFmt,
    required this.timeFmt,
    required this.onTapRecord,
  });

  final AttendanceDaySummary day;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final ValueChanged<RegistrosAsistencia> onTapRecord;

  @override
  State<EmployeeAttendanceDayCard> createState() => _EmployeeAttendanceDayCardState();
}

class _EmployeeAttendanceDayCardState extends State<EmployeeAttendanceDayCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.day;
    final first = widget.timeFmt.format(d.firstMark);
    final last = widget.timeFmt.format(d.lastMark);

    final showIncomplete = d.isIncomplete;
    final showGeofence = d.hasGeofenceIssues;
    final hasFlags = showIncomplete || showGeofence;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.dateFmt.format(d.day),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ),
                            if (!hasFlags)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.successGreen,
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniPill(
                              icon: Icons.timer_outlined,
                              text: _fmtDuration(d.workedNet),
                              color: AppColors.infoBlue,
                            ),
                            _MiniPill(
                              icon: Icons.schedule,
                              text: '$first → $last',
                              color: AppColors.neutral700,
                            ),
                            if (showIncomplete)
                              const _FlagChip(
                                text: 'Incompleto',
                                color: AppColors.warningOrange,
                              ),
                            if (showGeofence)
                              const _FlagChip(
                                text: 'Fuera de geocerca',
                                color: AppColors.errorRed,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.neutral500,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _expanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: AppColors.neutral200),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        itemCount: d.records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = d.records[index];
                          return _RecordRow(
                            record: r,
                            timeFmt: widget.timeFmt,
                            onTap: () => widget.onTapRecord(r),
                          );
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.record,
    required this.timeFmt,
    required this.onTap,
  });

  final RegistrosAsistencia record;
  final DateFormat timeFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = attendanceTypeStyle(record.tipoRegistro ?? '');
    final time = timeFmt.format(record.fechaHoraMarcacion);

    final branch = (record.sucursalNombre ?? '').trim();
    final branchLabel =
        branch.isNotEmpty ? branch : (record.sucursalId != null ? _shortId(record.sucursalId!) : '—');

    final geo = record.estaDentroGeocerca;
    final geoWidget = switch (geo) {
      true => const Icon(Icons.verified, color: AppColors.successGreen, size: 16),
      false => _Pill(label: 'Fuera', color: AppColors.errorRed),
      _ => _Pill(label: '—', color: AppColors.neutral500),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          style.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      geoWidget,
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    branchLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 3),
                const Icon(Icons.chevron_right, color: AppColors.neutral400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String text;
  final Color color;
  const _FlagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;


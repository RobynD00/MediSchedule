// One scheduled dose and what happened to it (matches the backend DoseResponse).
class DoseRecord {
  final int id;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final String? notes;
  final String patientName;
  final DateTime scheduledAt;
  final DateTime? respondedAt;
  final String status; // PENDING, TAKEN, SNOOZED, SKIPPED or MISSED
  final int snoozeCount;

  const DoseRecord({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.notes,
    required this.patientName,
    required this.scheduledAt,
    required this.respondedAt,
    required this.status,
    required this.snoozeCount,
  });

  factory DoseRecord.fromJson(Map<String, dynamic> json) {
    return DoseRecord(
      id: json['id'] as int,
      medicationId: json['medicationId'] as int,
      medicationName: json['medicationName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      notes: json['notes'] as String?,
      patientName: json['patientName'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      status: json['status'] as String? ?? 'PENDING',
      snoozeCount: json['snoozeCount'] as int? ?? 0,
    );
  }
}

// Caregiver dashboard numbers (matches AdherenceSummaryResponse).
class AdherenceSummary {
  final String patientName;
  final int days;
  final int taken;
  final int missed;
  final int skipped;
  final int total;
  final int adherencePercent;
  final List<DoseRecord> recent;

  const AdherenceSummary({
    required this.patientName,
    required this.days,
    required this.taken,
    required this.missed,
    required this.skipped,
    required this.total,
    required this.adherencePercent,
    required this.recent,
  });

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    return AdherenceSummary(
      patientName: json['patientName'] as String? ?? '',
      days: json['days'] as int? ?? 7,
      taken: json['taken'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      adherencePercent: json['adherencePercent'] as int? ?? 0,
      recent: [
        for (final item in (json['recent'] as List<dynamic>? ?? []))
          DoseRecord.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

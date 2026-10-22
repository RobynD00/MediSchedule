// Link between an elderly user and a caregiver (matches the backend CaregiverLinkResponse).
class CaregiverLink {
  final int id;
  final int patientId;
  final String patientName;
  final String caregiverName;
  final String caregiverContact;
  final bool canViewAdherence;
  final String status; // PENDING, ACCEPTED or REVOKED

  const CaregiverLink({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.caregiverName,
    required this.caregiverContact,
    required this.canViewAdherence,
    required this.status,
  });

  bool get isAccepted => status == 'ACCEPTED';

  factory CaregiverLink.fromJson(Map<String, dynamic> json) {
    return CaregiverLink(
      id: json['id'] as int,
      patientId: json['patientId'] as int,
      patientName: json['patientName'] as String? ?? '',
      caregiverName: json['caregiverName'] as String? ?? '',
      caregiverContact: json['caregiverContact'] as String? ?? '',
      canViewAdherence: json['canViewAdherence'] as bool? ?? false,
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

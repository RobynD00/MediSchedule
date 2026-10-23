import 'package:medischedule/models/caregiver_link.dart';
import 'package:medischedule/models/dose_record.dart';
import 'package:medischedule/services/api_client.dart';

// Caregiver links, missed-dose alerts and dashboard (backend: CaregiverController).
class CaregiverService {
  // ----- elderly user side -----
  static Future<List<CaregiverLink>> myCaregivers() async =>
      _links(await ApiClient.get('/api/caregivers/mine'));

  static Future<void> invite({
    required String name,
    required String contact,
    required bool canViewAdherence,
  }) async {
    await ApiClient.post(
      '/api/caregivers/link',
      body: {
        'caregiverName': name,
        'caregiverContact': contact,
        'canViewAdherence': canViewAdherence,
      },
    );
  }

  static Future<void> remove(int linkId) async {
    await ApiClient.delete('/api/caregivers/links/$linkId');
  }

  // ----- caregiver side -----
  static Future<List<CaregiverLink>> invitations() async =>
      _links(await ApiClient.get('/api/caregivers/invitations'));

  static Future<void> accept(int linkId) async {
    await ApiClient.post('/api/caregivers/links/$linkId/accept');
  }

  static Future<List<CaregiverLink>> patients() async =>
      _links(await ApiClient.get('/api/caregivers/patients'));

  // Missed doses of everyone this caregiver looks after.
  static Future<List<DoseRecord>> alerts({int days = 7}) async {
    final json = await ApiClient.get(
      '/api/caregivers/alerts',
      query: {'days': '$days'},
    );
    return [
      for (final item in json as List<dynamic>)
        DoseRecord.fromJson(item as Map<String, dynamic>),
    ];
  }

  static Future<AdherenceSummary> adherence(int patientId, {int days = 7}) async {
    final json = await ApiClient.get(
      '/api/caregivers/patients/$patientId/adherence',
      query: {'days': '$days'},
    );
    return AdherenceSummary.fromJson(json as Map<String, dynamic>);
  }

  static List<CaregiverLink> _links(dynamic json) => [
    for (final item in json as List<dynamic>)
      CaregiverLink.fromJson(item as Map<String, dynamic>),
  ];
}

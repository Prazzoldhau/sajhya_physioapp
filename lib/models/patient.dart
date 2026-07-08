class Patient {
  final int id;
  final String patientCode;
  final String patientName;
  final String patientContact;
  final String patientDiagnosis;
  final int completedSession;
  final String createdAt;

  const Patient({
    required this.id,
    required this.patientCode,
    required this.patientName,
    required this.patientContact,
    required this.patientDiagnosis,
    required this.completedSession,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
        id: j['id'] as int,
        patientCode: j['patient_code'] as String,
        patientName: j['patient_name'] as String,
        patientContact: j['patient_contact'] as String? ?? '',
        patientDiagnosis: j['patient_diagnosis'] as String? ?? '',
        completedSession: j['completed_session'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
      );
}

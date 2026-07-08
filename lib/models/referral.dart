import 'package:flutter/material.dart';

class Referral {
  final String referralCode;
  final String patientName;
  final String patientDiagnosis;
  final String patientContact;
  final String reason;
  final String notes;
  final String status;
  final String? referredTo;
  final int? referredToId;
  final String? referredBy;
  final String createdAt;
  final String? patientCode;
  final bool isAddressedToMe;

  const Referral({
    required this.referralCode,
    required this.patientName,
    required this.patientDiagnosis,
    required this.patientContact,
    required this.reason,
    required this.notes,
    required this.status,
    this.referredTo,
    this.referredToId,
    this.referredBy,
    required this.createdAt,
    this.patientCode,
    this.isAddressedToMe = true,
  });

  factory Referral.fromJson(Map<String, dynamic> j) => Referral(
        referralCode: j['referral_code'] as String,
        patientName: j['patient_name'] as String,
        patientDiagnosis: j['patient_diagnosis'] as String? ?? '',
        patientContact: j['patient_contact'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        referredTo: j['referred_to'] as String?,
        referredToId: j['referred_to_id'] as int?,
        referredBy: j['referred_by'] as String?,
        createdAt: j['created_at'] as String? ?? '',
        patientCode: j['patient_code'] as String?,
        isAddressedToMe: j['is_addressed_to_me'] as bool? ?? true,
      );

  Color get statusColor => switch (status) {
        'pending' => const Color(0xFFFFC107),
        'accepted' => const Color(0xFF0DCAF0),
        'in_progress' => const Color(0xFF0D6EFD),
        'completed' => const Color(0xFF198754),
        'rejected' => const Color(0xFFDC3545),
        _ => const Color(0xFF6C757D),
      };
}

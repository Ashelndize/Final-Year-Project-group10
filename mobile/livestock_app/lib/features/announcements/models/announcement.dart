import 'package:flutter/material.dart';

class OfficialAnnouncement {
  final int id;
  final String title;
  final String announcementType;
  final String announcementTypeDisplay;
  final String content;
  final String preventionGuidance;
  final String affectedAreaName;
  final String affectedSpecies;
  final String status;
  final String? issuingAuthorityName;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? withdrawnAt;
  final String withdrawalReason;
  final String targetAudience;
  final String targetAudienceDisplay;
  final DateTime createdAt;

  const OfficialAnnouncement({
    required this.id,
    required this.title,
    required this.announcementType,
    required this.announcementTypeDisplay,
    required this.content,
    required this.preventionGuidance,
    required this.affectedAreaName,
    required this.affectedSpecies,
    required this.status,
    this.issuingAuthorityName,
    this.publishedAt,
    this.expiresAt,
    this.withdrawnAt,
    required this.withdrawalReason,
    required this.targetAudience,
    required this.targetAudienceDisplay,
    required this.createdAt,
  });

  factory OfficialAnnouncement.fromJson(Map<String, dynamic> json) {
    return OfficialAnnouncement(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      announcementType: json['announcement_type'] as String? ?? '',
      announcementTypeDisplay:
          json['announcement_type_display'] as String? ?? '',
      content: json['content'] as String? ?? '',
      preventionGuidance: json['prevention_guidance'] as String? ?? '',
      affectedAreaName: json['affected_area_name'] as String? ?? '',
      affectedSpecies: json['affected_species'] as String? ?? '',
      status: json['status'] as String? ?? '',
      issuingAuthorityName: json['issuing_authority_name'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      withdrawnAt: json['withdrawn_at'] != null
          ? DateTime.parse(json['withdrawn_at'] as String)
          : null,
      withdrawalReason: json['withdrawal_reason'] as String? ?? '',
      targetAudience: json['target_audience'] as String? ?? 'ALL',
      targetAudienceDisplay: json['target_audience_display'] as String? ?? 'All Users',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPublished => status == 'PUBLISHED';
  bool get isWithdrawn => status == 'WITHDRAWN';
  bool get isOutbreakAlert => announcementType == 'OUTBREAK_ALERT';

  Color get audienceColor {
    switch (targetAudience) {
      case 'FARMERS_ONLY':
        return Colors.green;
      case 'VETS_ONLY':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  IconData get audienceIcon {
    switch (targetAudience) {
      case 'FARMERS_ONLY':
        return Icons.agriculture;
      case 'VETS_ONLY':
        return Icons.local_hospital_outlined;
      default:
        return Icons.people_outline;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PUBLISHED':
        return Colors.green;
      case 'WITHDRAWN':
        return Colors.grey;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color get typeColor {
    switch (announcementType) {
      case 'OUTBREAK_ALERT':
        return Colors.red;
      case 'ADVISORY':
        return Colors.orange;
      case 'WITHDRAWAL':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

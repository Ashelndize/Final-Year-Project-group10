import 'package:flutter/material.dart';

class DiseaseReport {
  final int id;
  final int reporter;
  final String reporterUsername;
  final int? farm;
  final String? farmName;
  final String species;
  final String speciesDisplay;
  final String observationDate;
  final int? area;
  final String? areaDisplay;
  final String areaName;
  final String observedSigns;
  final String notes;
  final String status;
  final String statusDisplay;
  final bool isConfirmedOutbreak;
  final double? reportLatitude;
  final double? reportLongitude;
  final bool locationConsent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiseaseReport({
    required this.id,
    required this.reporter,
    required this.reporterUsername,
    this.farm,
    this.farmName,
    required this.species,
    required this.speciesDisplay,
    required this.observationDate,
    this.area,
    this.areaDisplay,
    required this.areaName,
    required this.observedSigns,
    required this.notes,
    required this.status,
    required this.statusDisplay,
    required this.isConfirmedOutbreak,
    this.reportLatitude,
    this.reportLongitude,
    required this.locationConsent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiseaseReport.fromJson(Map<String, dynamic> json) {
    return DiseaseReport(
      id: json['id'] as int,
      reporter: json['reporter'] as int,
      reporterUsername: json['reporter_username'] as String? ?? '',
      farm: json['farm'] as int?,
      farmName: json['farm_name'] as String?,
      species: json['species'] as String? ?? '',
      speciesDisplay: json['species_display'] as String? ?? '',
      observationDate: json['observation_date'] as String? ?? '',
      area: json['area'] as int?,
      areaDisplay: json['area_display'] as String?,
      areaName: json['area_name'] as String? ?? '',
      observedSigns: json['observed_signs'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'SUBMITTED',
      statusDisplay: json['status_display'] as String? ?? 'Submitted',
      isConfirmedOutbreak: json['is_confirmed_outbreak'] as bool? ?? false,
      reportLatitude: json['report_latitude'] != null
          ? double.tryParse(json['report_latitude'].toString())
          : null,
      reportLongitude: json['report_longitude'] != null
          ? double.tryParse(json['report_longitude'].toString())
          : null,
      locationConsent: json['location_consent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'SUBMITTED':
        return Colors.blue;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'ACCEPTED_FOR_ASSESSMENT':
        return Colors.purple;
      case 'REJECTED':
        return Colors.red;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

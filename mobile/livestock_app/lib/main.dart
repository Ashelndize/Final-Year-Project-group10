import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/farms/providers/farm_provider.dart';
import 'features/animals/providers/animal_provider.dart';
import 'features/health/providers/health_provider.dart';
import 'features/vaccinations/providers/vaccination_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/veterinary/providers/assistance_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'features/announcements/providers/announcement_provider.dart';
import 'features/assistant/providers/assistant_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AssistanceProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
      ],
      child: const LivestockApp(),
    ),
  );
}

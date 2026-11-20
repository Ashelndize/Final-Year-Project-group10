import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/farms/providers/farm_provider.dart';
import 'features/animals/providers/animal_provider.dart';
import 'features/health/providers/health_provider.dart';
import 'features/vaccinations/providers/vaccination_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

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
      ],
      child: const LivestockApp(),
    ),
  );
}

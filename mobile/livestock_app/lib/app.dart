import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/providers/auth_provider.dart';
import 'router/app_router.dart';

class LivestockApp extends StatefulWidget {
  const LivestockApp({super.key});

  @override
  State<LivestockApp> createState() => _LivestockAppState();
}

class _LivestockAppState extends State<LivestockApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Livestock Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      routerConfig: _router,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}

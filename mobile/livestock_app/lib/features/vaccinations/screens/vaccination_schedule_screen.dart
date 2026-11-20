import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vaccination_provider.dart';
import '../../../core/widgets/app_widgets.dart';

class VaccinationScheduleScreen extends StatefulWidget {
  const VaccinationScheduleScreen({super.key});

  @override
  State<VaccinationScheduleScreen> createState() =>
      _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState
    extends State<VaccinationScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccinationProvider>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Schedule'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<VaccinationProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return const LoadingWidget(message: 'Loading schedules...');
          }
          if (provider.error != null) {
            return ErrorWidget2(
              message: provider.error!,
              onRetry: provider.loadSchedules,
            );
          }
          if (provider.schedules.isEmpty) {
            return const EmptyWidget(
              message: 'No vaccination schedules found.',
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadSchedules,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.schedules.length,
              itemBuilder: (_, i) {
                final s = provider.schedules[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Color(s.statusColor).withValues(alpha: 0.15),
                      child: Icon(
                        Icons.vaccines,
                        color: Color(s.statusColor),
                      ),
                    ),
                    title: Text(
                      s.protocolName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${s.animalTag} · Due: ${s.dueDate}'),
                    trailing: Chip(
                      label: Text(
                        s.status,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor:
                          Color(s.statusColor).withValues(alpha: 0.15),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

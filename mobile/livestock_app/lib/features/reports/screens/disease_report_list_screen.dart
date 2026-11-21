import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/report_provider.dart';
import '../models/disease_report.dart';

class DiseaseReportListScreen extends StatefulWidget {
  const DiseaseReportListScreen({super.key});

  @override
  State<DiseaseReportListScreen> createState() =>
      _DiseaseReportListScreenState();
}

class _DiseaseReportListScreenState extends State<DiseaseReportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Disease Reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/reports/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
      body: provider.loading
          ? const LoadingWidget()
          : provider.error != null
              ? ErrorWidget2(
                  message: provider.error!,
                  onRetry: () => context.read<ReportProvider>().loadReports(),
                )
              : provider.reports.isEmpty
                  ? const EmptyWidget(
                      message: 'No disease reports submitted.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: provider.reports.length,
                      itemBuilder: (_, i) =>
                          _ReportCard(report: provider.reports[i]),
                    ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final DiseaseReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: report.statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.bug_report, color: report.statusColor),
        ),
        title: Text(
          report.speciesDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.observedSigns,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              report.areaName.isNotEmpty
                  ? report.areaName
                  : (report.areaDisplay ?? ''),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Observed: ${report.observationDate}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            report.statusDisplay,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: report.statusColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

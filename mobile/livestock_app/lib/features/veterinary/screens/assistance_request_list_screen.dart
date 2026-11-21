import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/assistance_provider.dart';
import '../models/vet_assistance_request.dart';

class AssistanceRequestListScreen extends StatefulWidget {
  const AssistanceRequestListScreen({super.key});

  @override
  State<AssistanceRequestListScreen> createState() =>
      _AssistanceRequestListScreenState();
}

class _AssistanceRequestListScreenState
    extends State<AssistanceRequestListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistanceProvider>().loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Assistance Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/assistance/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: provider.loading
          ? const LoadingWidget()
          : provider.error != null
              ? ErrorWidget2(
                  message: provider.error!,
                  onRetry: () =>
                      context.read<AssistanceProvider>().loadRequests(),
                )
              : provider.requests.isEmpty
                  ? const EmptyWidget(
                      message: 'No assistance requests yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: provider.requests.length,
                      itemBuilder: (_, i) =>
                          _RequestCard(request: provider.requests[i]),
                    ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final VetAssistanceRequest request;
  const _RequestCard({required this.request});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(request.status).withValues(alpha: 0.15),
          child: Icon(
            Icons.medical_services,
            color: _statusColor(request.status),
          ),
        ),
        title: Text(
          request.farmName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (request.areaName.isNotEmpty)
              Text(
                request.areaName,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            request.statusDisplay,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: _statusColor(request.status),
        ),
        onTap: () {},
      ),
    );
  }
}

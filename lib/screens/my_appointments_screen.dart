import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../utils.dart';
import '../widgets.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late Future<List<Appointment>> _future = Api.myAppointments();

  Future<void> _refresh() async {
    final f = Api.myAppointments();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _cancel(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('${a.serviceName} at ${a.salonName}\n${dateTimeFmt.format(a.startsAt)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel it')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.cancel(a.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _refresh);

        final all = snap.data!;
        final upcoming = all.where((a) => a.isUpcoming).toList();
        final past = all.where((a) => !a.isUpcoming).toList().reversed.toList();

        if (all.isEmpty) {
          return const Center(child: Text('No appointments yet.\nFind a salon and book one!',
              textAlign: TextAlign.center));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) _header(context, 'Upcoming'),
              ...upcoming.map((a) => _AppointmentCard(a, onCancel: () => _cancel(a))),
              if (past.isNotEmpty) _header(context, 'Past & cancelled'),
              ...past.map((a) => _AppointmentCard(a)),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _AppointmentCard extends StatelessWidget {
  final Appointment a;
  final VoidCallback? onCancel;
  const _AppointmentCard(this.a, {this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = a.status == 'cancelled';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(a.serviceName, style: theme.textTheme.titleMedium)),
                if (cancelled)
                  Chip(
                    label: const Text('Cancelled'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.salonName),
            Text(a.salonAddress, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.event, size: 16),
              const SizedBox(width: 6),
              Text(dateTimeFmt.format(a.startsAt)),
            ]),
            Row(children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 6),
              Text('${a.stylistName} · ${a.durationMinutes} min · ${formatPrice(a.price)}'),
            ]),
            if (a.notes != null && a.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${a.notes}', style: theme.textTheme.bodySmall),
            ],
            if (onCancel != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ),
          ],
        ),
      ),
    );
  }
}

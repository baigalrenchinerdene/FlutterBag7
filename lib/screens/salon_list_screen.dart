import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets.dart';
import 'salon_detail_screen.dart';

class SalonListScreen extends StatefulWidget {
  const SalonListScreen({super.key});

  @override
  State<SalonListScreen> createState() => _SalonListScreenState();
}

class _SalonListScreenState extends State<SalonListScreen> {
  late Future<List<Salon>> _future = Api.salons();
  String _query = '';

  Future<void> _refresh() async {
    final f = Api.salons();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or area',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Salon>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return ErrorView(error: snap.error!, onRetry: _refresh);
              }
              final salons = snap.data!.where((s) {
                final hay = '${s.name} ${s.address} ${s.city ?? ''}'.toLowerCase();
                return hay.contains(_query);
              }).toList();
              if (salons.isEmpty) {
                return const Center(child: Text('No salons found.'));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: salons.length,
                  itemBuilder: (_, i) => _SalonCard(salon: salons[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SalonCard extends StatelessWidget {
  final Salon salon;
  const _SalonCard({required this.salon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SalonDetailScreen(salon: salon)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SalonImage(url: salon.imageUrl, height: 140),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(salon.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(salon.address, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text('Open ${salon.hoursLabel}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

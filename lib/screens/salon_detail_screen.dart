import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../utils.dart';
import '../widgets.dart';
import 'booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final Salon salon;
  const SalonDetailScreen({super.key, required this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  late Future<List<Service>> _services = Api.services(widget.salon.id);

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(salon.name)),
      body: ListView(
        children: [
          SalonImage(url: salon.imageUrl, height: 200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(salon.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                _InfoRow(Icons.place_outlined,
                    '${salon.address}${salon.city != null ? ', ${salon.city}' : ''}'),
                if (salon.phone != null) _InfoRow(Icons.phone_outlined, salon.phone!),
                _InfoRow(Icons.schedule, salon.hoursLabel),
                if (salon.description != null) ...[
                  const SizedBox(height: 12),
                  Text(salon.description!),
                ],
                const SizedBox(height: 24),
                Text('Services', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                FutureBuilder<List<Service>>(
                  future: _services,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return ErrorView(
                        error: snap.error!,
                        onRetry: () =>
                            setState(() => _services = Api.services(salon.id)),
                      );
                    }
                    final services = snap.data!;
                    if (services.isEmpty) {
                      return const Text('This salon has not added services yet.');
                    }
                    return Column(
                      children: services
                          .map((s) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(s.name),
                                  subtitle: Text(
                                      '${s.durationMinutes} min · ${formatPrice(s.price)}'),
                                  trailing: FilledButton.tonal(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BookingScreen(salon: salon, service: s),
                                      ),
                                    ),
                                    child: const Text('Book'),
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

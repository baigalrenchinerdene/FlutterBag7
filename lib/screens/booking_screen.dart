import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../utils.dart';

class BookingScreen extends StatefulWidget {
  final Salon salon;
  final Service service;
  const BookingScreen({super.key, required this.salon, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _notes = TextEditingController();
  late final List<DateTime> _days;
  late DateTime _day;

  List<Stylist> _stylists = [];
  Stylist? _stylist;
  List<DateTime> _slots = [];
  DateTime? _slot;

  bool _loadingStylists = true;
  bool _loadingSlots = false;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(14, (i) => DateTime(now.year, now.month, now.day + i));
    _day = _days.first;
    _loadStylists();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _loadStylists() async {
    try {
      final list = await Api.stylists(widget.salon.id);
      if (!mounted) return;
      setState(() {
        _stylists = list;
        _stylist = list.isNotEmpty ? list.first : null;
        _loadingStylists = false;
      });
      _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStylists = false);
      _toast('Could not load stylists: $e');
    }
  }

  Future<void> _loadSlots() async {
    final stylist = _stylist;
    final day = _day;
    if (stylist == null) return;
    setState(() {
      _loadingSlots = true;
      _slot = null;
    });
    try {
      final open = widget.salon.open, close = widget.salon.close;
      final start = DateTime(day.year, day.month, day.day, open.hour, open.minute);
      final end = DateTime(day.year, day.month, day.day, close.hour, close.minute);
      final busy = await Api.busySlots(stylist.id, start, end);
      // Ignore the result if the user already picked something else.
      if (!mounted || stylist != _stylist || day != _day) return;
      setState(() {
        _slots = buildSlots(
          dayStart: start,
          dayEnd: end,
          durationMin: widget.service.durationMinutes,
          busy: busy,
        );
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slots = [];
        _loadingSlots = false;
      });
      _toast('Could not load times: $e');
    }
  }

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _booking = true);
    try {
      await Api.book(
        serviceId: widget.service.id,
        stylistId: _stylist!.id,
        startsAt: _slot!,
        notes: _notes.text,
      );
      nav.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('Appointment booked! ✂️')));
    } on BookingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      _loadSlots(); // refresh – the slot may have just been taken
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: _loadingStylists
          ? const Center(child: CircularProgressIndicator())
          : _stylists.isEmpty
              ? const Center(child: Text('No stylists available at this salon.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.content_cut),
                        title: Text(service.name),
                        subtitle: Text(
                            '${widget.salon.name} · ${service.durationMinutes} min'),
                        trailing: Text(formatPrice(service.price),
                            style: theme.textTheme.titleMedium),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Stylist', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _stylists
                          .map((s) => ChoiceChip(
                                label: Text(s.name),
                                selected: _stylist?.id == s.id,
                                onSelected: (_) {
                                  setState(() => _stylist = s);
                                  _loadSlots();
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Date', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = _days[i];
                          return ChoiceChip(
                            selected: d == _day,
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat.E().format(d)),
                                Text('${d.day}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            onSelected: (_) {
                              setState(() => _day = d);
                              _loadSlots();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Time', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_loadingSlots)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_slots.isEmpty)
                      const Text('No free times on this day. Try another date or stylist.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots
                            .map((t) => ChoiceChip(
                                  label: Text(timeFmt.format(t)),
                                  selected: _slot == t,
                                  onSelected: (_) => setState(() => _slot = t),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes for the stylist (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (_slot == null || _booking) ? null : _confirm,
                      child: _booking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_slot == null
                              ? 'Pick a time'
                              : 'Confirm · ${dateTimeFmt.format(_slot!)}'),
                    ),
                  ],
                ),
    );
  }
}

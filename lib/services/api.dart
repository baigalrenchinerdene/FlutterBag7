import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// UI-only demo mode: everything lives in memory (resets when the app restarts).
/// The method signatures match what a real backend would expose, so you can
/// swap this file for a real implementation later without touching the screens.

class BookingException implements Exception {
  final String message;
  BookingException(this.message);
  @override
  String toString() => message;
}

class Auth {
  static final signedIn = ValueNotifier<bool>(false);
  static String name = 'Guest';

  static void signIn(String email, {String? fullName}) {
    name = (fullName != null && fullName.isNotEmpty) ? fullName : email.split('@').first;
    signedIn.value = true;
  }

  static void signOut() => signedIn.value = false;
}

DateTime _at(int dayOffset, int hour, [int minute = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + dayOffset, hour, minute);
}

class _Busy {
  final String stylistId;
  final String? appointmentId; // null = booked by "someone else"
  final DateTime start, end;
  _Busy(this.stylistId, this.start, this.end, [this.appointmentId]);
}

final _salons = <Salon>[
  Salon(
    id: 's1',
    name: 'Nomin Hair Studio',
    address: 'Peace Avenue 12, Sukhbaatar District',
    city: 'Ulaanbaatar',
    phone: '+976 7011 1234',
    description: 'Cuts, colour and styling in the city centre.',
    openTime: '10:00:00',
    closeTime: '20:00:00',
  ),
  Salon(
    id: 's2',
    name: 'Gobi Barber & Beauty',
    address: 'Baga Toiruu 45, Chingeltei District',
    city: 'Ulaanbaatar',
    phone: '+976 7022 5678',
    description: 'Modern barbershop and beauty salon.',
    openTime: '09:00:00',
    closeTime: '19:00:00',
  ),
  Salon(
    id: 's3',
    name: 'Altan Salon & Spa',
    address: 'Seoul Street 8, Bayanzurkh District',
    city: 'Ulaanbaatar',
    phone: '+976 7033 9012',
    description: 'Relaxing hair treatments, styling and nails.',
    openTime: '11:00:00',
    closeTime: '21:00:00',
  ),
];

final _services = <Service>[
  Service(id: 'v1', salonId: 's1', name: "Women's haircut", durationMinutes: 60, price: 35000),
  Service(id: 'v2', salonId: 's1', name: "Men's haircut", durationMinutes: 30, price: 20000),
  Service(id: 'v3', salonId: 's1', name: 'Hair colouring', durationMinutes: 120, price: 90000),
  Service(id: 'v4', salonId: 's1', name: 'Blow-dry & style', durationMinutes: 45, price: 25000),
  Service(id: 'v5', salonId: 's2', name: 'Classic haircut', durationMinutes: 30, price: 18000),
  Service(id: 'v6', salonId: 's2', name: 'Beard trim', durationMinutes: 30, price: 12000),
  Service(id: 'v7', salonId: 's2', name: 'Haircut + beard', durationMinutes: 60, price: 28000),
  Service(id: 'v8', salonId: 's3', name: 'Keratin treatment', durationMinutes: 150, price: 120000),
  Service(id: 'v9', salonId: 's3', name: 'Updo / event styling', durationMinutes: 60, price: 45000),
  Service(id: 'v10', salonId: 's3', name: 'Haircut & wash', durationMinutes: 45, price: 30000),
];

final _stylists = <Stylist>[
  Stylist(id: 'st1', salonId: 's1', name: 'Nomin', bio: 'Senior stylist'),
  Stylist(id: 'st2', salonId: 's1', name: 'Anu', bio: 'Colour specialist'),
  Stylist(id: 'st3', salonId: 's2', name: 'Temuulen', bio: 'Master barber'),
  Stylist(id: 'st4', salonId: 's2', name: 'Bat-Erdene', bio: 'Fades and beard design'),
  Stylist(id: 'st5', salonId: 's3', name: 'Oyuna', bio: 'Keratin & styling'),
  Stylist(id: 'st6', salonId: 's3', name: 'Saruul', bio: 'Updos and events'),
];

int _nextId = 100;

// Some slots are already taken so the UI shows realistic availability.
final _busy = <_Busy>[
  for (final st in _stylists) ...[
    _Busy(st.id, _at(0, 14), _at(0, 15)),
    _Busy(st.id, _at(1, 11), _at(1, 12)),
    _Busy(st.id, _at(1, 15), _at(1, 16, 30)),
    _Busy(st.id, _at(2, 13), _at(2, 14)),
  ],
  _Busy('st1', _at(3, 12), _at(3, 13), 'a1'),
];

final _appointments = <Appointment>[
  Appointment(
    id: 'a1',
    status: 'confirmed',
    salonName: 'Nomin Hair Studio',
    salonAddress: 'Peace Avenue 12, Sukhbaatar District',
    serviceName: "Women's haircut",
    stylistName: 'Nomin',
    startsAt: _at(3, 12),
    endsAt: _at(3, 13),
    price: 35000,
    durationMinutes: 60,
  ),
  Appointment(
    id: 'a0',
    status: 'completed',
    salonName: 'Gobi Barber & Beauty',
    salonAddress: 'Baga Toiruu 45, Chingeltei District',
    serviceName: 'Classic haircut',
    stylistName: 'Temuulen',
    startsAt: _at(-7, 15),
    endsAt: _at(-7, 15, 30),
    price: 18000,
    durationMinutes: 30,
  ),
];

Future<void> _delay() => Future.delayed(const Duration(milliseconds: 400));

class Api {
  static Future<List<Salon>> salons() async {
    await _delay();
    return List.of(_salons);
  }

  static Future<List<Service>> services(String salonId) async {
    await _delay();
    return _services.where((s) => s.salonId == salonId).toList();
  }

  static Future<List<Stylist>> stylists(String salonId) async {
    await _delay();
    return _stylists.where((s) => s.salonId == salonId).toList();
  }

  static Future<List<BusySlot>> busySlots(
      String stylistId, DateTime from, DateTime to) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _busy
        .where((b) => b.stylistId == stylistId && b.start.isBefore(to) && b.end.isAfter(from))
        .map((b) => BusySlot(b.start, b.end))
        .toList();
  }

  static Future<void> book({
    required String serviceId,
    required String stylistId,
    required DateTime startsAt,
    String? notes,
  }) async {
    await _delay();
    final service = _services.firstWhere((s) => s.id == serviceId);
    final stylist = _stylists.firstWhere((s) => s.id == stylistId);
    final salon = _salons.firstWhere((s) => s.id == service.salonId);
    final endsAt = startsAt.add(Duration(minutes: service.durationMinutes));

    if (!startsAt.isAfter(DateTime.now())) {
      throw BookingException('You cannot book a time in the past.');
    }
    final clash = _busy.any((b) =>
        b.stylistId == stylistId && startsAt.isBefore(b.end) && endsAt.isAfter(b.start));
    if (clash) {
      throw BookingException('That time was just taken. Please choose another slot.');
    }

    final id = 'a${_nextId++}';
    _busy.add(_Busy(stylistId, startsAt, endsAt, id));
    _appointments.add(Appointment(
      id: id,
      status: 'confirmed',
      salonName: salon.name,
      salonAddress: salon.address,
      serviceName: service.name,
      stylistName: stylist.name,
      startsAt: startsAt,
      endsAt: endsAt,
      price: service.price,
      durationMinutes: service.durationMinutes,
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    ));
  }

  static Future<List<Appointment>> myAppointments() async {
    await _delay();
    final list = List.of(_appointments)..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  static Future<void> cancel(String appointmentId) async {
    await _delay();
    final i = _appointments.indexWhere((a) => a.id == appointmentId);
    if (i < 0) throw BookingException('Appointment not found.');
    final a = _appointments[i];
    _appointments[i] = Appointment(
      id: a.id,
      status: 'cancelled',
      salonName: a.salonName,
      salonAddress: a.salonAddress,
      serviceName: a.serviceName,
      stylistName: a.stylistName,
      startsAt: a.startsAt,
      endsAt: a.endsAt,
      price: a.price,
      durationMinutes: a.durationMinutes,
      notes: a.notes,
    );
    _busy.removeWhere((b) => b.appointmentId == appointmentId);
  }
}

import 'package:flutter/material.dart';

TimeOfDay _parseTime(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

class Salon {
  final String id, name, address, openTime, closeTime;
  final String? city, phone, description, imageUrl;

  Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.openTime,
    required this.closeTime,
    this.city,
    this.phone,
    this.description,
    this.imageUrl,
  });

  factory Salon.fromJson(Map<String, dynamic> j) => Salon(
        id: j['id'],
        name: j['name'],
        address: j['address'],
        city: j['city'],
        phone: j['phone'],
        description: j['description'],
        imageUrl: j['image_url'],
        openTime: j['open_time'],
        closeTime: j['close_time'],
      );

  TimeOfDay get open => _parseTime(openTime);
  TimeOfDay get close => _parseTime(closeTime);
  String get hoursLabel =>
      '${openTime.substring(0, 5)} – ${closeTime.substring(0, 5)}';
}

class Service {
  final String id, salonId, name;
  final String? description;
  final int durationMinutes;
  final num price;

  Service({
    required this.id,
    required this.salonId,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.description,
  });

  factory Service.fromJson(Map<String, dynamic> j) => Service(
        id: j['id'],
        salonId: j['salon_id'],
        name: j['name'],
        description: j['description'],
        durationMinutes: j['duration_minutes'],
        price: j['price'],
      );
}

class Stylist {
  final String id, salonId, name;
  final String? bio;

  Stylist({required this.id, required this.salonId, required this.name, this.bio});

  factory Stylist.fromJson(Map<String, dynamic> j) => Stylist(
        id: j['id'],
        salonId: j['salon_id'],
        name: j['name'],
        bio: j['bio'],
      );
}

class BusySlot {
  final DateTime start, end;
  BusySlot(this.start, this.end);
}

class Appointment {
  final String id, status, salonName, salonAddress, serviceName, stylistName;
  final DateTime startsAt, endsAt;
  final num price;
  final int durationMinutes;
  final String? notes;

  Appointment({
    required this.id,
    required this.status,
    required this.salonName,
    required this.salonAddress,
    required this.serviceName,
    required this.stylistName,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.durationMinutes,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        id: j['id'],
        status: j['status'],
        startsAt: DateTime.parse(j['starts_at']).toLocal(),
        endsAt: DateTime.parse(j['ends_at']).toLocal(),
        notes: j['notes'],
        salonName: j['salons']['name'],
        salonAddress: j['salons']['address'],
        serviceName: j['services']['name'],
        price: j['services']['price'],
        durationMinutes: j['services']['duration_minutes'],
        stylistName: j['stylists']['name'],
      );

  bool get isUpcoming => status == 'confirmed' && endsAt.isAfter(DateTime.now());
}

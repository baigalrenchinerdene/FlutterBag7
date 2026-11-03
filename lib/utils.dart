import 'package:intl/intl.dart';
import 'models/models.dart';

final _money = NumberFormat('#,##0', 'en_US');
String formatPrice(num price) => '${_money.format(price)}₮';

final dateTimeFmt = DateFormat('EEE, MMM d · HH:mm');
final timeFmt = DateFormat('HH:mm');

/// Builds the list of bookable start times for one day.
/// Slots start every [stepMin] minutes between opening and closing time,
/// must finish before closing, be in the future and not overlap [busy].
List<DateTime> buildSlots({
  required DateTime dayStart,
  required DateTime dayEnd,
  required int durationMin,
  required List<BusySlot> busy,
  int stepMin = 30,
}) {
  final now = DateTime.now();
  final result = <DateTime>[];
  var t = dayStart;
  while (!t.add(Duration(minutes: durationMin)).isAfter(dayEnd)) {
    final end = t.add(Duration(minutes: durationMin));
    final clash = busy.any((b) => t.isBefore(b.end) && end.isAfter(b.start));
    if (t.isAfter(now) && !clash) result.add(t);
    t = t.add(Duration(minutes: stepMin));
  }
  return result;
}

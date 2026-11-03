import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking/main.dart';

void main() {
  testWidgets('Salon app startup test', (tester) async {
    await tester.pumpWidget(const SalonApp());

    expect(find.byType(SalonApp), findsOneWidget);
  });
}

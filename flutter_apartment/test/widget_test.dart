import 'package:flutter_test/flutter_test.dart';

import 'package:skyline_heights_flutter/main.dart';

void main() {
  testWidgets('shows login screen on startup', (tester) async {
    await tester.pumpWidget(const SkylineHeightsApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Resident'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}

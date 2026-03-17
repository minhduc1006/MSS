import 'package:flutter_test/flutter_test.dart';

import 'package:skyline_heights_flutter/main.dart';

void main() {
  testWidgets('shows login screen on startup', (tester) async {
    await tester.pumpWidget(const SkylineHeightsApp());
    await tester.pumpAndSettle();

    expect(find.text('Skyline Heights'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}

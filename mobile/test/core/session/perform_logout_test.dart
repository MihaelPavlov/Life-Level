import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_level/core/api/api_client.dart';
import 'package:life_level/core/session/invalidate_user_providers.dart';
import 'package:life_level/features/auth/login_screen.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => performLogout(context),
              child: const Text('Logout'),
            ),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('logout opens Login straight away and clears the token',
      (tester) async {
    await ApiClient.saveToken('jwt');
    await _pumpApp(tester);

    await tester.tap(find.text('Logout'));
    // Local work only before the route change: a few frames, no network.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
    expect(await ApiClient.getToken(), isNull);
    expect(find.text('Signed out'), findsOneWidget);

    // Let the toast and the background cleanup finish.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a second tap does not start a second logout', (tester) async {
    await ApiClient.saveToken('jwt');
    await _pumpApp(tester);

    await tester.tap(find.text('Logout'));
    await tester.tap(find.text('Logout'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}

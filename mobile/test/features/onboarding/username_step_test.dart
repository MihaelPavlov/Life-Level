import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/auth/models/account_models.dart';
import 'package:life_level/features/auth/services/auth_service.dart';
import 'package:life_level/features/character/setup/setup_resume_service.dart';
import 'package:life_level/features/onboarding/onboarding_controller.dart';
import 'package:life_level/features/onboarding/screens/username_step.dart';

class _FakeAuth extends AuthService {
  final taken = {'runner', 'swiftfalcon'};
  final chosen = <String>[];

  @override
  Future<AccountInfo> getAccount() async => const AccountInfo(
      username: 'PlayerK7QD',
      email: 'p@example.com',
      hasPassword: false,
      googleConnected: true);

  @override
  Future<String?> usernameProblem(String username) async =>
      taken.contains(username.toLowerCase()) ? 'That name is taken.' : null;

  @override
  Future<String> chooseUsername(String username) async {
    chosen.add(username);
    return username;
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<(OnboardingController, _FakeAuth)> pump(WidgetTester tester) async {
    final auth = _FakeAuth();
    final ctrl = OnboardingController(
        const SetupResumeState(step: SetupStep.username, ringItems: []));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: OnboardingScope(
          controller: ctrl,
          child: UsernameStep(authService: auth),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (ctrl, auth);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('username-field')), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }


  testWidgets('rules are checked as you type', (tester) async {
    await pump(tester);
    await type(tester, 'ab');
    expect(find.text('At least 3 characters'), findsOneWidget);
    await type(tester, 'bad-name');
    expect(find.text('Only letters, numbers and _'), findsOneWidget);
  });

  testWidgets('a taken name offers ideas that can be tapped', (tester) async {
    await pump(tester);
    await type(tester, 'Runner');
    expect(find.text('That name is taken.'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(3));
    await tester.tap(find.text('Runner_LL'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('claiming an available name saves it and moves on',
      (tester) async {
    final (ctrl, auth) = await pump(tester);
    await type(tester, 'Night_Owl');
    expect(find.text('Available'), findsOneWidget);
    await tester.tap(find.text('CLAIM NAME'));
    await tester.pumpAndSettle();
    expect(auth.chosen, ['Night_Owl']);
    expect(ctrl.step, SetupStep.welcome);
  });

  testWidgets('keeping the generated name also moves on', (tester) async {
    final (ctrl, auth) = await pump(tester);
    await tester.tap(find.text('Keep PlayerK7QD for now'));
    await tester.pumpAndSettle();
    expect(auth.chosen, ['PlayerK7QD']);
    expect(ctrl.step, SetupStep.welcome);
  });

  testWidgets('the dice fills in a name', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('username-dice')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(const Key('username-field')));
    expect(field.controller!.text, matches(RegExp(r'^[A-Za-z]+\d*$')));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/auth/login_screen.dart';
import 'package:life_level/features/auth/register_screen.dart';
import 'package:life_level/features/character/setup/setup_resume_service.dart';
import 'package:life_level/features/onboarding/onboarding_controller.dart';
import 'package:life_level/features/onboarding/screens/username_step.dart';
import 'package:life_level/features/onboarding/screens/welcome_step.dart';
import 'package:life_level/features/auth/models/account_models.dart';
import 'package:life_level/features/auth/services/auth_service.dart';

class _GoldenAuth extends AuthService {
  @override
  Future<AccountInfo> getAccount() async => const AccountInfo(
      username: 'PlayerK7QD',
      email: 'p@example.com',
      hasPassword: false,
      googleConnected: true);

  @override
  Future<String?> usernameProblem(String username) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login screen golden', (tester) async {
    await pumpScreen(tester, const LoginScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });

  testWidgets('register screen golden', (tester) async {
    await pumpScreen(tester, const RegisterScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/register_screen.png'),
    );
  });

  testWidgets('onboarding welcome golden', (tester) async {
    final ctrl = OnboardingController(
      const SetupResumeState(
          step: SetupStep.welcome, ringItems: ['boss', 'guild', 'world']),
    );
    await pumpScreen(
      tester,
      // Reduced motion renders every entrance in its final state.
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: OnboardingScope(controller: ctrl, child: const WelcomeStep()),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_welcome.png'),
    );
  });

  testWidgets('onboarding username golden', (tester) async {
    final ctrl = OnboardingController(
      const SetupResumeState(step: SetupStep.username, ringItems: []),
    );
    await pumpScreen(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: OnboardingScope(
            controller: ctrl, child: UsernameStep(authService: _GoldenAuth())),
      ),
    );
    await tester.enterText(find.byType(TextField), 'SwiftFalcon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_username.png'),
    );
  });
}

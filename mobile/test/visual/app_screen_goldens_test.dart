import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/auth/login_screen.dart';
import 'package:life_level/features/auth/register_screen.dart';
import 'package:life_level/features/character/models/character_class.dart';
import 'package:life_level/features/character/setup/avatar_selection_screen.dart';
import 'package:life_level/features/character/setup/welcome_setup_screen.dart';

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

  testWidgets('welcome setup screen golden', (tester) async {
    await pumpScreen(
      tester,
      const WelcomeSetupScreen(ringItems: ['boss', 'guild', 'world']),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/welcome_setup_screen.png'),
    );
  });

  testWidgets('avatar selection screen golden', (tester) async {
    await pumpScreen(
      tester,
      AvatarSelectionScreen(
        selectedClass: const CharacterClass(
          id: 'warrior',
          name: 'Warrior',
          emoji: '⚔️',
          description: 'Front-line physical specialist',
          tagline: 'Power through every challenge',
          strMultiplier: 1.3,
          endMultiplier: 1.1,
          agiMultiplier: 1.0,
          flxMultiplier: 1.0,
          staMultiplier: 1.2,
        ),
        ringItems: const ['boss', 'guild', 'world'],
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/avatar_selection_screen.png'),
    );
  });
}

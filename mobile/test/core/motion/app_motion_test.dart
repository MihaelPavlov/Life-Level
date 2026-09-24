import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/motion/app_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('motion preference is persisted', () async {
    final settings = AppMotionSettings();
    await settings.setPreference(AppMotionPreference.reduced);

    expect(settings.preference, AppMotionPreference.reduced);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_motion_preference'), 'reduced');
  });

  testWidgets('device reduced motion caps a full preference', (tester) async {
    final settings = AppMotionSettings();
    await settings.setPreference(AppMotionPreference.full);
    AppMotionPreference? effective;

    await tester.pumpWidget(
      AppMotionScope(
        settings: settings,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              effective = AppMotion.effectivePreference(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(effective, AppMotionPreference.reduced);
  });

  testWidgets('off mode makes shared durations immediate', (tester) async {
    final settings = AppMotionSettings();
    await settings.setPreference(AppMotionPreference.off);
    Duration? duration;

    await tester.pumpWidget(
      AppMotionScope(
        settings: settings,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              duration = AppMotion.duration(
                context,
                AppMotionTokens.sheetEnter,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(duration, Duration.zero);
  });

  testWidgets('shared bottom sheet opens and returns its result',
      (tester) async {
    final settings = AppMotionSettings();
    await settings.setPreference(AppMotionPreference.off);
    String? result;

    await tester.pumpWidget(
      AppMotionScope(
        settings: settings,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppBottomSheet<String>(
                  context: context,
                  builder: (sheetContext) => TextButton(
                    onPressed: () => Navigator.pop(sheetContext, 'claimed'),
                    child: const Text('Claim'),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Claim'), findsOneWidget);

    await tester.tap(find.text('Claim'));
    await tester.pump();
    expect(result, 'claimed');
  });

  testWidgets('animated indexed stack keeps inactive tab state',
      (tester) async {
    final settings = AppMotionSettings();
    await settings.setPreference(AppMotionPreference.off);
    var index = 0;
    late StateSetter setHostState;

    await tester.pumpWidget(
      AppMotionScope(
        settings: settings,
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return AppAnimatedIndexedStack(
                index: index,
                children: const [_CounterTab(), Text('Second')],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    setHostState(() => index = 1);
    await tester.pumpAndSettle();
    setHostState(() => index = 0);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}

class _CounterTab extends StatefulWidget {
  const _CounterTab();

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('$count'),
    );
  }
}

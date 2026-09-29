import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/character/models/character_class.dart';
import 'package:life_level/features/character/setup/setup_resume_service.dart';
import 'package:life_level/features/onboarding/models/onboarding_models.dart';
import 'package:life_level/features/onboarding/onboarding_controller.dart';
import 'package:life_level/features/onboarding/screens/avatar_step.dart';
import 'package:life_level/features/onboarding/screens/class_step.dart';

CharacterClass _cls(String id, String name,
        {double str = 1, double end = 1, double agi = 1, double flx = 1, double sta = 1, bool hybrid = false}) =>
    CharacterClass(
      id: id,
      name: name,
      emoji: '',
      description: '$name description',
      tagline: '$name tagline',
      strMultiplier: str,
      endMultiplier: end,
      agiMultiplier: agi,
      flxMultiplier: flx,
      staMultiplier: sta,
      isHybrid: hybrid,
    );

final _classes = [
  _cls('ranger', 'Ranger', end: 1.3, agi: 1.2),
  _cls('warrior', 'Warrior', str: 1.3, sta: 1.2),
  _cls('mystic', 'Mystic', flx: 1.4, sta: 1.2),
  _cls('sentinel', 'Sentinel', end: 1.1, sta: 1.4),
  _cls('tidecaller', 'Tidecaller', end: 1.2, flx: 1.1, sta: 1.2),
  _cls('cragborn', 'Cragborn', str: 1.2, agi: 1.2, flx: 1.1),
  _cls('wayfarer', 'Wayfarer', end: 1.2, sta: 1.3),
  _cls('spellblade', 'Spellblade', str: 1.2, flx: 1.2, agi: 1.1, hybrid: true),
];

ClassRecommendation _rec(
  ClassDetectionState state, {
  String? pick,
  List<String> alts = const [],
  String? trait,
  String? devoted,
  List<ClassShare> shares = const [],
  int workouts = 12,
}) =>
    ClassRecommendation(
      state: state,
      recommendedClassId: pick,
      alternativeClassIds: alts,
      traitKey: trait,
      devotedActivityType: devoted,
      shares: shares,
      activities: [
        if (devoted != null) ActivityShare(devoted, 18, 864, .96),
      ],
      workoutCount: workouts,
      activeMinutes: 900,
      classes: _classes,
    );

Future<OnboardingController> _pump(
    WidgetTester tester, ClassRecommendation rec, Widget screen,
    {String? source = 'strava'}) async {
  final ctrl = OnboardingController(SetupResumeState(
    step: SetupStep.classReveal,
    ringItems: const [],
    source: source,
  ));
  ctrl.recommendation = rec;
  if (rec.recommendedClassId != null) {
    ctrl.chooseClass(rec.recommended!);
  }
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(430, 1400), disableAnimations: true),
      child: OnboardingScope(controller: ctrl, child: screen),
    ),
  ));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  return ctrl;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('clear: shows the detected class and a change link',
      (tester) async {
    await _pump(
      tester,
      _rec(ClassDetectionState.clear, pick: 'ranger', alts: const ['warrior'], shares: const [
        ClassShare('ranger', 'Ranger', 750, .61),
        ClassShare('warrior', 'Warrior', 220, .18),
      ]),
      const ClassStep(),
    );
    expect(find.text('Ranger'), findsWidgets);
    expect(find.text('61% MATCH'), findsOneWidget);
    expect(find.text('CONTINUE AS RANGER'), findsOneWidget);
    expect(find.text('Choose a different class'), findsOneWidget);
  });

  testWidgets('devoted: grants the trait while the detected class is kept',
      (tester) async {
    await _pump(
      tester,
      _rec(ClassDetectionState.devoted,
          pick: 'ranger', trait: 'devoted:Running', devoted: 'Running', shares: const [
        ClassShare('ranger', 'Ranger', 864, .96),
      ]),
      const ClassStep(),
    );
    expect(find.text('Devoted Ranger'), findsOneWidget);
    expect(find.text('Trait · Devoted Runner'), findsOneWidget);
    expect(find.text('CONTINUE AS DEVOTED RANGER'), findsOneWidget);
  });

  testWidgets('hybrid: offers the hybrid and both parents', (tester) async {
    final ctrl = await _pump(
      tester,
      _rec(ClassDetectionState.hybrid,
          pick: 'spellblade', alts: const ['warrior', 'mystic'], shares: const [
        ClassShare('warrior', 'Warrior', 220, .51),
        ClassShare('mystic', 'Mystic', 210, .49),
      ]),
      const ClassStep(),
    );
    expect(find.text('HYBRID CLASS FOUND'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(find.text('CONTINUE AS SPELLBLADE'), findsOneWidget);

    await tester.tap(find.text('Mystic').last);
    await tester.pump();
    expect(ctrl.chosenClass?.name, 'Mystic');
    expect(ctrl.classSource, 'changed');
    expect(find.text('CONTINUE AS MYSTIC'), findsOneWidget);
  });

  testWidgets('insufficient: manual picker hides hybrids until one is picked',
      (tester) async {
    final ctrl = await _pump(
      tester,
      _rec(ClassDetectionState.insufficient, workouts: 2),
      const ClassStep(),
    );
    expect(find.text('PICK A CLASS'), findsOneWidget);
    expect(find.text('Spellblade'), findsNothing);
    expect(find.text('🔒 Hybrids'), findsOneWidget);

    await tester.tap(find.text('Wayfarer'));
    await tester.pump();
    expect(ctrl.chosenClass?.name, 'Wayfarer');
    expect(ctrl.classSource, 'manual');
    expect(find.text('CONTINUE AS WAYFARER'), findsOneWidget);
  });

  testWidgets('avatar: pre-selects the avatar that suits the class',
      (tester) async {
    final ctrl = await _pump(
      tester,
      _rec(ClassDetectionState.clear, pick: 'warrior', shares: const [
        ClassShare('warrior', 'Warrior', 600, .8),
      ]),
      const AvatarStep(),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(ctrl.avatarEmoji, '⚔️');
    expect(find.text('SUITS WARRIOR'), findsOneWidget);
    expect(suggestedAvatarFor('Spellblade'), '🥷');
  });
}

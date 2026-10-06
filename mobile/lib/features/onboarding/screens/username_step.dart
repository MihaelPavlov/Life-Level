import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../auth/services/auth_service.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// "Name your hero": the first step for players who signed up with Google or
/// Apple, who otherwise keep a generated name like PlayerK7QD.
class UsernameStep extends StatefulWidget {
  /// Injectable for tests.
  final AuthService? authService;
  const UsernameStep({super.key, this.authService});

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

enum _Check { idle, checking, available, problem }

class _UsernameStepState extends State<UsernameStep>
    with SingleTickerProviderStateMixin {
  late final AuthService _auth = widget.authService ?? AuthService();
  final _field = TextEditingController();
  final _focus = FocusNode();
  late final _dice = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));

  String? _current;
  _Check _check = _Check.idle;
  String? _problem;
  String? _error;
  bool _saving = false;
  Timer? _debounce;
  Timer? _shuffle;
  int _lookup = 0;
  final _random = math.Random();

  static final _pattern = RegExp(r'^[A-Za-z0-9_]+$');

  @override
  void initState() {
    super.initState();
    _field.addListener(_onChanged);
    _auth.getAccount().then((a) {
      if (mounted) setState(() => _current = a.username);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _shuffle?.cancel();
    _field.dispose();
    _focus.dispose();
    _dice.dispose();
    super.dispose();
  }

  String get _name => _field.text.trim();

  /// Rules checked on the device first; the server confirms the rest.
  String? _localProblem(String name) {
    if (name.length < 3) return 'At least 3 characters';
    if (name.length > 20) return '20 characters at most';
    if (!_pattern.hasMatch(name)) return 'Only letters, numbers and _';
    return null;
  }

  void _onChanged() {
    _debounce?.cancel();
    final name = _name;
    if (name.isEmpty) {
      setState(() {
        _check = _Check.idle;
        _problem = null;
        _error = null;
      });
      return;
    }
    final local = _localProblem(name);
    if (local != null) {
      setState(() {
        _check = _Check.problem;
        _problem = local;
        _error = null;
      });
      return;
    }
    setState(() {
      _check = _Check.checking;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () => _lookUp(name));
  }

  Future<void> _lookUp(String name) async {
    final id = ++_lookup;
    try {
      final problem = await _auth.usernameProblem(name);
      if (!mounted || id != _lookup || name != _name) return;
      setState(() {
        _check = problem == null ? _Check.available : _Check.problem;
        _problem = problem;
      });
    } catch (_) {
      // Offline or server hiccup: let CLAIM try and report the real answer.
      if (!mounted || id != _lookup) return;
      setState(() => _check = _Check.idle);
    }
  }

  void _roll() {
    if (_saving) return;
    HapticFeedback.selectionClick();
    _dice.forward(from: 0);
    _shuffle?.cancel();
    var ticks = 0;
    _shuffle = Timer.periodic(const Duration(milliseconds: 60), (t) {
      ticks++;
      final name = heroNameIdea(_random);
      _field.value = TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
      );
      if (ticks >= 7) t.cancel();
    });
  }

  void _use(String name) {
    _field.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  Future<void> _save(String name) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _auth.chooseUsername(name);
      if (!mounted) return;
      OnboardingScope.read(context).next();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        if (name == _name) {
          _check = _Check.problem;
          _problem = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> get _ideas {
    final base = _name.length > 16 ? _name.substring(0, 16) : _name;
    return [
      '$base${10 + _random.nextInt(90)}',
      '${base}_LL',
      heroNameIdea(_random),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = _check == _Check.available && !_saving;
    final (statusText, statusColor) = switch (_check) {
      _Check.idle => ('3–20 letters, numbers or _', AppColors.textSecondary),
      _Check.checking => ('Checking…', AppColors.textSecondary),
      _Check.available => ('Available', AppColors.green),
      _Check.problem => (_problem ?? '', AppColors.red),
    };
    final borderColor = switch (_check) {
      _Check.available => AppColors.green,
      _Check.problem => AppColors.red,
      _ => _focus.hasFocus ? AppColors.blue : AppColors.surfaceElevated,
    };
    final showIdeas =
        _check == _Check.problem && _problem == 'That name is taken.';

    return OnboardingScaffold(
      glow: AppColors.purple,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Text(
              'ONE LAST THING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 26),
            const Center(
              child: Entrance.pop(
                child: SizedBox(
                  width: 130,
                  height: 144,
                  child: CustomPaint(
                    painter: OnboardingHexPainter(),
                    child: Center(
                      child: AppIconImage(AppIcons.avatarWizard, size: 58),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const OnboardingTitle(
              'Name your hero',
              align: TextAlign.center,
              subtitle:
                  'This is how friends, guilds and leaderboards see you.',
            ),
            const SizedBox(height: 28),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: _check == _Check.available ||
                        _check == _Check.problem
                    ? [
                        BoxShadow(
                          color: borderColor.withValues(alpha: .15),
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('username-field'),
                      controller: _field,
                      focusNode: _focus,
                      enabled: !_saving,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      maxLength: 20,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onTap: () => setState(() {}),
                      onSubmitted: (_) {
                        if (canClaim) _save(_name);
                      },
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Hero name',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        hintText: 'e.g. SwiftFalcon',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_check == _Check.available)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_rounded,
                          size: 20, color: AppColors.green),
                    )
                  else if (_check == _Check.problem)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: AppColors.red),
                    ),
                  _DiceButton(animation: _dice, onTap: _saving ? null : _roll),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            if (showIdeas) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final idea in _ideas)
                    ActionChip(
                      label: Text(idea),
                      onPressed: () => _use(idea),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                    ),
                ],
              ),
            ],
            if (_error != null && !showIdeas) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingButton(
            label: 'CLAIM NAME',
            busy: _saving,
            onPressed: canClaim ? () => _save(_name) : null,
          ),
          if (_current != null)
            OnboardingTextLink(
              'Keep $_current for now',
              onTap: () {
                if (!_saving) _save(_current!);
              },
            ),
        ],
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback? onTap;
  const _DiceButton({required this.animation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Roll a random hero name',
      child: Material(
        color: AppColors.purple.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.purple.withValues(alpha: .5)),
        ),
        child: InkWell(
          key: const Key('username-dice'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: RotationTransition(
              turns: CurvedAnimation(
                  parent: animation, curve: Curves.easeOutBack),
              child: const Icon(Icons.casino_outlined,
                  size: 22, color: AppColors.purple),
            ),
          ),
        ),
      ),
    );
  }
}

const _nameStarts = [
  'Swift', 'Iron', 'Storm', 'Ember', 'Silent', 'Wild', 'Lunar', 'Brave',
  'Frost', 'Golden', 'Shadow', 'Thunder', 'Crimson', 'Rapid', 'Steel',
];
const _nameEnds = [
  'Falcon', 'Runner', 'Strider', 'Wolf', 'Comet', 'Ranger', 'Fox', 'Titan',
  'Hawk', 'Nomad', 'Rider', 'Knight', 'Pacer', 'Sprinter', 'Warden',
];

/// A fantasy name like "SwiftFalcon"; sometimes with a number, so a taken
/// pair still has a free variant.
String heroNameIdea(math.Random random) {
  final name = _nameStarts[random.nextInt(_nameStarts.length)] +
      _nameEnds[random.nextInt(_nameEnds.length)];
  return random.nextInt(3) == 0 ? '$name${random.nextInt(90) + 10}' : name;
}

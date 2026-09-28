import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/constants/title_rank_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/models/character_profile.dart';
import '../models/title_models.dart';
import 'title_equip_flight.dart';

class TitlesProfileHeader extends StatefulWidget {
  final TitlesAndRanksResponse data;
  final CharacterProfile profile;

  /// When set, the nameplate is the landing spot for the equip flight:
  /// the old title falls off at launch and the plate squashes and shines
  /// on landing.
  final TitleEquipFlight? flight;

  const TitlesProfileHeader({
    super.key,
    required this.data,
    required this.profile,
    this.flight,
  });

  @override
  State<TitlesProfileHeader> createState() => _TitlesProfileHeaderState();
}

class _TitlesProfileHeaderState extends State<TitlesProfileHeader>
    with TickerProviderStateMixin {
  // Old title knocked off the plate while the new one is in the air.
  late final AnimationController _fall = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  // Landing: squash (0–380 ms) and shine sweep (180–700 ms).
  late final AnimationController _land = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  bool _wasInFlight = false;
  int _landings = 0;

  TitlesAndRanksResponse get data => widget.data;
  CharacterProfile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    _listen(widget.flight);
  }

  @override
  void didUpdateWidget(covariant TitlesProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flight != widget.flight) {
      oldWidget.flight?.removeListener(_onFlight);
      _listen(widget.flight);
    }
  }

  void _listen(TitleEquipFlight? flight) {
    _wasInFlight = flight?.inFlight ?? false;
    _landings = flight?.landings ?? 0;
    flight?.addListener(_onFlight);
  }

  void _onFlight() {
    final flight = widget.flight!;
    if (flight.inFlight && !_wasInFlight) {
      _fall.duration =
          AppMotion.duration(context, const Duration(milliseconds: 260));
      _fall.forward(from: 0);
    } else if (!flight.inFlight && _wasInFlight) {
      _fall.value = 0;
    }
    if (flight.landings != _landings && AppMotion.isFull(context)) {
      _land.forward(from: 0);
    }
    _wasInFlight = flight.inFlight;
    _landings = flight.landings;
  }

  @override
  void dispose() {
    widget.flight?.removeListener(_onFlight);
    _fall.dispose();
    _land.dispose();
    super.dispose();
  }

  /// Plate squash on landing: wide-and-flat, then tall-and-thin, settle.
  Offset get _squash {
    final ms = _land.value * 700;
    if (!_land.isAnimating || ms >= 380) return const Offset(1, 1);
    final t = ms / 380;
    double seg(double a, double b, double p) => a + (b - a) * p;
    if (t < 1 / 3) {
      final p = Curves.easeOut.transform(t * 3);
      return Offset(seg(1, 1.14, p), seg(1, .86, p));
    }
    if (t < 2 / 3) {
      final p = Curves.easeInOut.transform((t - 1 / 3) * 3);
      return Offset(seg(1.14, .97, p), seg(.86, 1.04, p));
    }
    final p = Curves.easeOut.transform((t - 2 / 3) * 3);
    return Offset(seg(.97, 1, p), seg(1.04, 1, p));
  }

  /// Shine sweep progress 0..1, or null when not sweeping.
  double? get _shine {
    final ms = _land.value * 700;
    if (!_land.isAnimating || ms < 180) return null;
    return Curves.easeInOut.transform(((ms - 180) / 520).clamp(0.0, 1.0));
  }

  Widget _plateFx({required Widget plate}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fall, _land]),
      builder: (_, __) {
        final sq = _squash;
        final shine = _shine;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sq.dx, sq.dy, 1),
          child: Stack(
            children: [
              plate,
              if (shine != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LayoutBuilder(
                        builder: (_, box) => Stack(children: [
                          Positioned(
                            left: -40 + (box.maxWidth + 60) * shine,
                            top: -4,
                            bottom: -4,
                            child: Transform(
                              transform: Matrix4.skewX(-.35),
                              child: Container(
                                width: 34,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color(0x00FFFFFF),
                                    Color(0xA6FFFFFF),
                                    Color(0x00FFFFFF),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The old title falling off the plate while the new one flies in.
  Widget _falling(Widget child) {
    return AnimatedBuilder(
      animation: _fall,
      child: child,
      builder: (_, c) {
        final p = Curves.easeIn.transform(_fall.value);
        if (p == 0) return c!;
        return Opacity(
          opacity: 1 - p,
          child: Transform.translate(
            offset: Offset(0, 16 * p),
            child: Transform.rotate(angle: .14 * p, child: c),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final hasTitle =
        data.activeTitleEmoji.isNotEmpty && data.activeTitleName.isNotEmpty;
    final activeTitleIcon = titleIconAsset(name: data.activeTitleName);
    final avatarAsset = avatarIconAsset(profile.avatarEmoji);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.purple.withOpacity(0.35),
                  AppColors.blue.withOpacity(0.12),
                ],
              ),
              border: Border.all(
                color: AppColors.purple.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: avatarAsset != null
                  ? AppIconImage(
                      avatarAsset,
                      size: 46,
                      visualScale: 1.45,
                    )
                  : Text(
                      profile.avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 32),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (hasTitle)
            _plateFx(
              plate: Container(
                key: flight?.plateKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: AnimatedSize(
                  duration: AppMotion.duration(
                      context, const Duration(milliseconds: 250)),
                  curve: Curves.easeOut,
                  child: _falling(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 320)),
                        transitionBuilder: (child, a) => ScaleTransition(
                          scale: CurvedAnimation(
                              parent: a, curve: Curves.easeOutBack),
                          child: RotationTransition(
                            turns: Tween(begin: -.25, end: 0.0).animate(a),
                            child: child,
                          ),
                        ),
                        child: activeTitleIcon != null
                            ? Padding(
                                key: ValueKey(activeTitleIcon),
                                padding: const EdgeInsets.only(right: 7),
                                child: AppIconImage(
                                  activeTitleIcon,
                                  size: 18,
                                  visualScale: 1.4,
                                ),
                              )
                            : Padding(
                                key: ValueKey(data.activeTitleEmoji),
                                padding: const EdgeInsets.only(right: 5),
                                child: Text(
                                  data.activeTitleEmoji,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                      ),
                      Flexible(
                        child: NameplateSwap(
                          data.activeTitleName,
                          // The flight already knocked the old title off.
                          slideOut: flight == null,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  )),
                ),
              ),
            )
          else
            Text(
              'No title equipped',
              key: flight?.plateKey,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Lv.${profile.level}  •  ${profile.xp} XP',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

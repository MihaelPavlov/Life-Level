import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../character_service.dart';
import '../models/character_class.dart';
import 'avatar_selection_screen.dart';
import 'welcome_setup_screen.dart' show setupProgressDots;

class ClassSelectionScreen extends StatefulWidget {
  final List<String> ringItems;
  const ClassSelectionScreen({super.key, required this.ringItems});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  final _service = CharacterService();
  List<CharacterClass>? _classes;
  CharacterClass? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _service.getClasses();
      setState(() {
        _classes = classes;
        _selected = classes.isNotEmpty ? classes.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load classes. Tap to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Purple gradient glow at top
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.9),
                radius: 1.2,
                colors: [Color(0x15a371f7), Color(0x00040810)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF30363d)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 14,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'STEP 2 OF 4',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose Your Class',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your class shapes your starting stat bonuses. You can change this later.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      setupProgressDots(current: 1, total: 4),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.purple))
                      : _error != null
                          ? Center(
                              child: GestureDetector(
                                onTap: _load,
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _classes!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _ClassCard(
                                cls: _classes![i],
                                selected:
                                    _selected?.id == _classes![i].id,
                                onTap: () => setState(
                                    () => _selected = _classes![i]),
                              ),
                            ),
                ),
              ],
            ),
          ),
          // Sticky CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AvatarSelectionScreen(
                              selectedClass: _selected!,
                              ringItems: widget.ringItems,
                            ),
                          ),
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  disabledBackgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'CONTINUE →',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final CharacterClass cls;
  final bool selected;
  final VoidCallback onTap;

  const _ClassCard({
    required this.cls,
    required this.selected,
    required this.onTap,
  });

  Color get _classColor {
    switch (cls.name.toLowerCase()) {
      case 'warrior':
        return AppColors.red;
      case 'ranger':
        return AppColors.green;
      case 'mystic':
        return AppColors.purple;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _classColor;
    final bonuses = _bonusList();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.05) : AppColors.surface,
          border: Border.all(
            color: selected
                ? color.withOpacity(0.6)
                : AppColors.surfaceElevated,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.12), blurRadius: 16)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(cls.emoji,
                          style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cls.tagline,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: bonuses
                            .map((b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: b.$2.withOpacity(0.12),
                                    border: Border.all(
                                        color: b.$2.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.$1,
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: b.$2),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.purple
                        : Colors.transparent,
                    border: Border.all(
                        color: selected
                            ? AppColors.purple
                            : const Color(0xFF30363d),
                        width: 1.5),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stat bars
            _statBar('STR', cls.strMultiplier, AppColors.red),
            const SizedBox(height: 4),
            _statBar('END', cls.endMultiplier, AppColors.blue),
            const SizedBox(height: 4),
            _statBar('AGI', cls.agiMultiplier, const Color(0xFF38d9c8)),
            const SizedBox(height: 4),
            _statBar('FLX', cls.flxMultiplier, AppColors.purple),
            const SizedBox(height: 4),
            _statBar('STA', cls.staMultiplier, AppColors.orange),
          ],
        ),
      ),
    );
  }

  List<(String, Color)> _bonusList() {
    final result = <(String, Color)>[];
    if (cls.strMultiplier > 1.0) {
      result.add(('+STR ×${cls.strMultiplier.toStringAsFixed(1)}', AppColors.red));
    }
    if (cls.endMultiplier > 1.0) {
      result.add(('+END ×${cls.endMultiplier.toStringAsFixed(1)}', AppColors.blue));
    }
    if (cls.agiMultiplier > 1.0) {
      result.add(('+AGI ×${cls.agiMultiplier.toStringAsFixed(1)}', const Color(0xFF38d9c8)));
    }
    if (cls.flxMultiplier > 1.0) {
      result.add(('+FLX ×${cls.flxMultiplier.toStringAsFixed(1)}', AppColors.purple));
    }
    if (cls.staMultiplier > 1.0) {
      result.add(('+STA ×${cls.staMultiplier.toStringAsFixed(1)}', AppColors.orange));
    }
    return result;
  }

  Widget _statBar(String key, double multiplier, Color color) {
    final fill =
        multiplier > 1.0 ? (0.3 + (multiplier - 1.0) * 1.5).clamp(0.0, 1.0) : 0.3;
    final val = (fill * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            key,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.surfaceElevated),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: multiplier > 1.0
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 4)
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: Text(
            '$val',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: multiplier > 1.0
                    ? color
                    : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

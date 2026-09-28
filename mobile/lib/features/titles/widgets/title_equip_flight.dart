import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/title_rank_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/title_models.dart';

/// Coordinates the "ribbon flight" on equip: the tapped title lifts off its
/// card as a glowing pill and flies into the profile header's nameplate,
/// knocking the old title off.
///
/// The screen owns one instance, hands [plateKey] to the header and
/// [nameKeyFor] to each card, and calls [launch] / [land] around the flight.
/// The header listens to drop the old title and to play the landing.
class TitleEquipFlight extends ChangeNotifier {
  /// On the header nameplate — the flight's destination.
  final plateKey = GlobalKey();
  final _nameKeys = <String, GlobalKey>{};

  /// On a card's title name — the flight's origin.
  GlobalKey nameKeyFor(String titleId) =>
      _nameKeys.putIfAbsent(titleId, GlobalKey.new);

  String? _flyingId;
  int _landings = 0;

  /// Id of the title in the air, null when idle.
  String? get flyingId => _flyingId;
  bool get inFlight => _flyingId != null;

  /// Increments on every landing; the header plays squash + shine on change.
  int get landings => _landings;

  void launch(String titleId) {
    _flyingId = titleId;
    notifyListeners();
  }

  void land() {
    _flyingId = null;
    _landings++;
    notifyListeners();
  }

  /// Flight aborted before landing — the header restores the old title.
  void cancel() {
    if (_flyingId == null) return;
    _flyingId = null;
    notifyListeners();
  }
}

/// The glowing pill that flies from the card to the nameplate.
class TitleGhostPill extends StatelessWidget {
  final TitleDto title;

  const TitleGhostPill({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final icon = titleIconAsset(id: title.id, name: title.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF221A0D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .55),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: AppIconImage(icon, size: 18, visualScale: 1.4),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                title.emoji,
                style: const TextStyle(
                    fontSize: 13, decoration: TextDecoration.none),
              ),
            ),
          Text(
            title.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

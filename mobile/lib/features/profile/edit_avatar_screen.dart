import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/avatar_icons.dart';
import '../../core/widgets/app_icon_image.dart';
import '../character/models/avatar_option.dart';
import '../character/providers/character_provider.dart';
import '../character/services/character_service.dart';
import 'profile_stat_metadata.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key});

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  late Future<List<AvatarOption>> _future;
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = CharacterService().getAvatars();
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _saving) return;

    setState(() => _saving = true);
    try {
      await CharacterService().updateAvatar(selected);
      await ref.read(characterProfileProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFrom(e, 'Could not update avatar.'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPBg,
      appBar: AppBar(
        backgroundColor: kPBg,
        foregroundColor: kPTextPri,
        title: const Text('Change Avatar'),
      ),
      body: FutureBuilder<List<AvatarOption>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                _messageFrom(snapshot.error, 'Failed to load avatars.'),
                style: const TextStyle(color: kPTextSec),
              ),
            );
          }

          final avatars = snapshot.data ?? const <AvatarOption>[];
          AvatarOption? equipped;
          for (final avatar in avatars) {
            if (avatar.isEquipped) {
              equipped = avatar;
              break;
            }
          }
          _selected ??= equipped?.emoji;

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (_, i) {
                    final avatar = avatars[i];
                    return _AvatarTile(
                      avatar: avatar,
                      selected: _selected == avatar.emoji,
                      onTap: avatar.isUnlocked
                          ? () => setState(() => _selected = avatar.emoji)
                          : null,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving || _selected == null ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        disabledBackgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_saving ? 'SAVING...' : 'SAVE AVATAR'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AvatarOption avatar;
  final bool selected;
  final VoidCallback? onTap;

  const _AvatarTile({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconAsset = avatarIconAsset(avatar.emoji);
    final locked = !avatar.isUnlocked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: locked ? 0.48 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.orange.withOpacity(0.10)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.orange.withOpacity(0.70)
                  : AppColors.surfaceElevated,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: iconAsset != null
                          ? AppIconImage(iconAsset, size: 52)
                          : Text(
                              avatar.emoji,
                              style: const TextStyle(fontSize: 38),
                            ),
                    ),
                  ),
                  Text(
                    avatar.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPTextPri,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: Text(
                      locked
                          ? avatar.unlockRequirement ?? 'Locked'
                          : avatar.isEquipped
                              ? 'Equipped'
                              : 'Unlocked',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: locked ? kPTextSec : AppColors.green,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (locked)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.lock, size: 16, color: kPTextSec),
                ),
              if (selected)
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(Icons.check_circle, size: 17, color: AppColors.orange),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _messageFrom(Object? error, String fallback) {
  final text = error.toString();
  final marker = RegExp(r'error:\s*([^}]+)');
  final match = marker.firstMatch(text);
  return match?.group(1)?.trim() ?? fallback;
}

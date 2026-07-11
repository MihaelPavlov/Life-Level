import 'app_icons.dart';

String? classIconAssetForName(String? className) {
  switch ((className ?? '').trim().toLowerCase()) {
    case 'warrior':
      return AppIcons.classWarrior;
    case 'ranger':
    case 'archer':
      return AppIcons.classArcher;
    case 'mystic':
      return AppIcons.classMystic;
    case 'sentinel':
      return AppIcons.classSentinel;
    default:
      return null;
  }
}

String? classIconAssetForEmoji(String? emoji) {
  switch ((emoji ?? '').trim()) {
    case '\u2694':
    case '\u2694\uFE0F':
      return AppIcons.classWarrior;
    case '\u{1F3F9}':
      return AppIcons.classArcher;
    case '\u{1F52E}':
    case '\u2726':
      return AppIcons.classMystic;
    case '\u{1F6E1}':
    case '\u{1F6E1}\uFE0F':
      return AppIcons.classSentinel;
    default:
      return null;
  }
}

String? classIconAsset({
  String? className,
  String? classEmoji,
}) {
  return classIconAssetForName(className) ?? classIconAssetForEmoji(classEmoji);
}

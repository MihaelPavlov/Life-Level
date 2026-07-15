import 'app_icons.dart';

String? avatarIconAsset(String? avatarEmoji) {
  switch (avatarEmoji) {
    case '🧙':
      return AppIcons.avatarWizard;
    case '⚔️':
      return AppIcons.avatarWarrior;
    case '🏹':
      return AppIcons.avatarArcher;
    case '🛡️':
      return AppIcons.avatarPaladin;
    case '🧘':
      return AppIcons.avatarMonk;
    case '🐺':
      return AppIcons.avatarWolf;
    case '🦊':
      return AppIcons.avatarFox;
    case '🥷':
      return AppIcons.avatarNinja;
    case '🦸':
      return AppIcons.avatarSuperhero;
    case '🧝':
      return AppIcons.avatarElf;
    case '👑':
      return AppIcons.avatarCrown;
    case '🌟':
      return AppIcons.avatarStar;
    case '💎':
      return AppIcons.avatarDiamond;
    case '🔮':
      return AppIcons.avatarMystic;
    case '⚡':
      return AppIcons.avatarLightning;
    case '🌙':
      return AppIcons.avatarMoon;
    default:
      return null;
  }
}

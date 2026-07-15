import 'app_icons.dart';

String? rankIconAsset(String rank) {
  switch (_normalize(rank)) {
    case 'novice':
      return AppIcons.rankNovice;
    case 'warrior':
      return AppIcons.rankWarrior;
    case 'veteran':
      return AppIcons.rankVeteran;
    case 'champion':
      return AppIcons.rankChampion;
    case 'legend':
      return AppIcons.rankLegend;
  }

  return null;
}

String? titleIconAsset({String? id, required String name}) {
  final normalizedId = _normalize(id ?? '');
  final normalizedName = _normalize(name).replaceFirst(RegExp(r'^the '), '');

  switch (normalizedId) {
    case 'a0000000 0000 0000 0000 000000000001':
      return AppIcons.titleMarathoner;
    case 'a0000000 0000 0000 0000 000000000002':
      return AppIcons.titleStreakMaster;
    case 'a0000000 0000 0000 0000 000000000003':
      return AppIcons.titleRaidVeteran;
    case 'a0000000 0000 0000 0000 000000000004':
      return AppIcons.title5amClub;
    case 'a0000000 0000 0000 0000 000000000005':
      return AppIcons.titleChampion;
    case 'a0000000 0000 0000 0000 000000000006':
      return AppIcons.titleUnstoppable;
    case 'a0000000 0000 0000 0000 000000000007':
    case 'novice adventurer':
      return AppIcons.titleNoviceAdventurer;
  }

  switch (normalizedName) {
    case 'marathoner':
      return AppIcons.titleMarathoner;
    case 'streak master':
      return AppIcons.titleStreakMaster;
    case 'raid veteran':
      return AppIcons.titleRaidVeteran;
    case '5am club':
      return AppIcons.title5amClub;
    case 'champion':
      return AppIcons.titleChampion;
    case 'unstoppable':
      return AppIcons.titleUnstoppable;
    case 'novice adventurer':
      return AppIcons.titleNoviceAdventurer;
  }

  return null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

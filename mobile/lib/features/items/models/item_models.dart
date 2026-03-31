class ItemDto {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String rarity;
  final String slotType;
  final int xpBonusPct;
  final int strBonus;
  final int endBonus;
  final int agiBonus;
  final int flxBonus;
  final int staBonus;
  final String? characterItemId;
  final bool isEquipped;
  final String category;

  const ItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.slotType,
    required this.xpBonusPct,
    required this.strBonus,
    required this.endBonus,
    required this.agiBonus,
    required this.flxBonus,
    required this.staBonus,
    this.characterItemId,
    this.isEquipped = false,
    this.category = 'Accessory',
  });

  factory ItemDto.fromJson(Map<String, dynamic> json) => ItemDto(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        rarity: json['rarity'] as String,
        slotType: json['slotType'] as String,
        xpBonusPct: json['xpBonusPct'] as int? ?? 0,
        strBonus: json['strBonus'] as int? ?? 0,
        endBonus: json['endBonus'] as int? ?? 0,
        agiBonus: json['agiBonus'] as int? ?? 0,
        flxBonus: json['flxBonus'] as int? ?? 0,
        staBonus: json['staBonus'] as int? ?? 0,
        characterItemId: json['characterItemId'] as String?,
        isEquipped: json['isEquipped'] as bool? ?? false,
        category: json['category'] as String? ?? 'Accessory',
      );
}

class EquipmentSlotDto {
  final String slotType;
  final ItemDto? item;

  const EquipmentSlotDto({required this.slotType, this.item});

  factory EquipmentSlotDto.fromJson(Map<String, dynamic> json) =>
      EquipmentSlotDto(
        slotType: json['slotType'] as String,
        item: json['item'] != null
            ? ItemDto.fromJson(json['item'] as Map<String, dynamic>)
            : null,
      );
}

class GearBonusesDto {
  final int xpBonusPct;
  final int strBonus;
  final int endBonus;
  final int agiBonus;
  final int flxBonus;
  final int staBonus;

  const GearBonusesDto({
    required this.xpBonusPct,
    required this.strBonus,
    required this.endBonus,
    required this.agiBonus,
    required this.flxBonus,
    required this.staBonus,
  });

  factory GearBonusesDto.fromJson(Map<String, dynamic> json) => GearBonusesDto(
        xpBonusPct: json['xpBonusPct'] as int? ?? 0,
        strBonus: json['strBonus'] as int? ?? 0,
        endBonus: json['endBonus'] as int? ?? 0,
        agiBonus: json['agiBonus'] as int? ?? 0,
        flxBonus: json['flxBonus'] as int? ?? 0,
        staBonus: json['staBonus'] as int? ?? 0,
      );

  bool get hasAnyBonus =>
      xpBonusPct > 0 ||
      strBonus > 0 ||
      endBonus > 0 ||
      agiBonus > 0 ||
      flxBonus > 0 ||
      staBonus > 0;
}

class CharacterEquipmentResponse {
  final List<EquipmentSlotDto> slots;
  final GearBonusesDto totalBonuses;

  const CharacterEquipmentResponse({
    required this.slots,
    required this.totalBonuses,
  });

  factory CharacterEquipmentResponse.fromJson(Map<String, dynamic> json) =>
      CharacterEquipmentResponse(
        slots: (json['slots'] as List<dynamic>)
            .map((e) => EquipmentSlotDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalBonuses: GearBonusesDto.fromJson(
            json['totalBonuses'] as Map<String, dynamic>),
      );

  EquipmentSlotDto? slotFor(String slotType) =>
      slots.where((s) => s.slotType == slotType).firstOrNull;
}

namespace LifeLevel.Modules.WorldZone.Domain.Enums;

public enum WorldZoneType
{
    Entry = 0,      // first zone in region
    Standard = 1,   // named story zone
    Crossroads = 2, // branching point
    Boss = 3,       // region-end boss
    Chest = 4,      // one-shot chest zone (reward XP on open)
    Dungeon = 5     // multi-floor dungeon zone (run through floors for bonus XP)
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class RemoveMapSeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Clear all user map state that references seed data before deleting seed rows
            migrationBuilder.Sql("DELETE FROM \"UserCrossroadsStates\";");
            migrationBuilder.Sql("DELETE FROM \"UserDungeonStates\";");
            migrationBuilder.Sql("DELETE FROM \"UserChestStates\";");
            migrationBuilder.Sql("DELETE FROM \"UserBossStates\";");
            migrationBuilder.Sql("DELETE FROM \"UserNodeUnlocks\";");
            migrationBuilder.Sql("DELETE FROM \"UserMapProgresses\";");

            migrationBuilder.DeleteData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0003-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Chests",
                keyColumn: "Id",
                keyValue: new Guid("eeeeeeee-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Chests",
                keyColumn: "Id",
                keyValue: new Guid("eeeeeeee-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CrossroadsPaths",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0101-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CrossroadsPaths",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0102-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CrossroadsPaths",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0201-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CrossroadsPaths",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0202-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "DungeonFloors",
                keyColumn: "Id",
                keyValue: new Guid("ffffffff-0101-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "DungeonFloors",
                keyColumn: "Id",
                keyValue: new Guid("ffffffff-0102-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "DungeonFloors",
                keyColumn: "Id",
                keyValue: new Guid("ffffffff-0103-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0003-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0004-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0005-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0006-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0007-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0008-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0009-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0010-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0011-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0012-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0013-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0014-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0015-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0016-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0017-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Crossroads",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Crossroads",
                keyColumn: "Id",
                keyValue: new Guid("11111111-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "DungeonPortals",
                keyColumn: "Id",
                keyValue: new Guid("ffffffff-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0011-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0012-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0013-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0014-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0015-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0016-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0017-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0010-0000-0000-000000000000"));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "MapNodes",
                columns: new[] { "Id", "Description", "Icon", "IsHidden", "IsStartNode", "LevelRequirement", "Name", "PositionX", "PositionY", "Region", "RewardXp", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0001-0000-0000-000000000000"), "The starting point of every hero's journey.", "🏰", false, true, 1, "Ashfield Gate", 500f, 900f, "Ashfield", 0, "Zone" },
                    { new Guid("bbbbbbbb-0002-0000-0000-000000000000"), "The edge of the Forest of Endurance. The trees grow thick here.", "🌲", false, false, 1, "Forest Entrance", 500f, 740f, "ForestOfEndurance", 100, "Zone" },
                    { new Guid("bbbbbbbb-0003-0000-0000-000000000000"), "A massive oak splits the path. Choose wisely.", "⑂", false, false, 2, "Ancient Oak Crossroads", 480f, 600f, "ForestOfEndurance", 150, "Crossroads" },
                    { new Guid("bbbbbbbb-0004-0000-0000-000000000000"), "A gentle valley winding through ancient trees.", "🌿", false, false, 2, "Valley Trail", 300f, 460f, "ForestOfEndurance", 150, "Zone" },
                    { new Guid("bbbbbbbb-0005-0000-0000-000000000000"), "An old road through the ruins. Harder, but rewarding.", "🗿", false, false, 3, "Ruined Pass", 640f, 470f, "ForestOfEndurance", 200, "Zone" },
                    { new Guid("bbbbbbbb-0006-0000-0000-000000000000"), "The ancient core of the forest, where the oldest trees stand.", "🌳", false, false, 5, "Forest Heart", 460f, 370f, "ForestOfEndurance", 300, "Zone" },
                    { new Guid("bbbbbbbb-0007-0000-0000-000000000000"), "The Thornback Guardian defends the forest depths.", "💀", false, false, 3, "Thornback Lair", 310f, 530f, "ForestOfEndurance", 200, "Boss" },
                    { new Guid("bbbbbbbb-0008-0000-0000-000000000000"), "The gateway to the Mountains of Strength.", "⛰️", false, false, 8, "Mountain Pass", 480f, 260f, "MountainsOfStrength", 450, "Zone" },
                    { new Guid("bbbbbbbb-0009-0000-0000-000000000000"), "A shimmering portal leading to an ancient dungeon.", "🌀", false, false, 8, "Iron Depths Portal", 640f, 310f, "MountainsOfStrength", 450, "Dungeon" },
                    { new Guid("bbbbbbbb-0010-0000-0000-000000000000"), "Two paths lead to the peak. One is treacherous.", "⑂", false, false, 10, "Summit Crossroads", 460f, 170f, "MountainsOfStrength", 600, "Crossroads" },
                    { new Guid("bbbbbbbb-0011-0000-0000-000000000000"), "The summit. Only the strongest reach this place.", "🏔️", true, false, 12, "Peak of Strength", 350f, 80f, "MountainsOfStrength", 800, "Zone" },
                    { new Guid("bbbbbbbb-0012-0000-0000-000000000000"), "The ocean breeze carries tales of balance and serenity.", "🌊", true, false, 10, "Coastal Road", 720f, 480f, "OceanOfBalance", 600, "Zone" },
                    { new Guid("bbbbbbbb-0013-0000-0000-000000000000"), "A chest left by a traveler long ago.", "📦", false, false, 1, "Traveler's Cache", 620f, 680f, "ForestOfEndurance", 100, "Chest" },
                    { new Guid("bbbbbbbb-0014-0000-0000-000000000000"), "A weathered chest at the mountain base.", "📦", false, false, 8, "Summit Cache", 370f, 300f, "MountainsOfStrength", 450, "Chest" },
                    { new Guid("bbbbbbbb-0015-0000-0000-000000000000"), "The air grows heavy. Something stirs in the murk.", "🌫️", true, false, 6, "Swamp Edge", 650f, 700f, "Swamps", 350, "Zone" },
                    { new Guid("bbbbbbbb-0016-0000-0000-000000000000"), "Strange fungi pulse with an eerie glow. Something lurks within.", "🍄", false, false, 2, "Mushroom Grove", 700f, 640f, "ForestOfEndurance", 150, "Boss" },
                    { new Guid("bbbbbbbb-0017-0000-0000-000000000000"), "Icy winds howl from the cave mouth. A predator has made its home here.", "❄️", false, false, 9, "Frost Cavern", 600f, 175f, "MountainsOfStrength", 500, "Boss" }
                });

            migrationBuilder.InsertData(
                table: "Bosses",
                columns: new[] { "Id", "Icon", "IsMini", "MaxHp", "Name", "NodeId", "RewardXp", "TimerDays" },
                values: new object[,]
                {
                    { new Guid("dddddddd-0001-0000-0000-000000000000"), "🦎", false, 500, "Thornback Guardian", new Guid("bbbbbbbb-0007-0000-0000-000000000000"), 800, 7 },
                    { new Guid("dddddddd-0002-0000-0000-000000000000"), "🍄", true, 200, "Sporebloom Shroom", new Guid("bbbbbbbb-0016-0000-0000-000000000000"), 300, 3 },
                    { new Guid("dddddddd-0003-0000-0000-000000000000"), "❄️", true, 350, "Frost Stalker", new Guid("bbbbbbbb-0017-0000-0000-000000000000"), 500, 3 }
                });

            migrationBuilder.InsertData(
                table: "Chests",
                columns: new[] { "Id", "NodeId", "Rarity", "RewardXp" },
                values: new object[,]
                {
                    { new Guid("eeeeeeee-0001-0000-0000-000000000000"), new Guid("bbbbbbbb-0013-0000-0000-000000000000"), "Common", 150 },
                    { new Guid("eeeeeeee-0002-0000-0000-000000000000"), new Guid("bbbbbbbb-0014-0000-0000-000000000000"), "Uncommon", 300 }
                });

            migrationBuilder.InsertData(
                table: "Crossroads",
                columns: new[] { "Id", "NodeId" },
                values: new object[,]
                {
                    { new Guid("11111111-0001-0000-0000-000000000000"), new Guid("bbbbbbbb-0003-0000-0000-000000000000") },
                    { new Guid("11111111-0002-0000-0000-000000000000"), new Guid("bbbbbbbb-0010-0000-0000-000000000000") }
                });

            migrationBuilder.InsertData(
                table: "DungeonPortals",
                columns: new[] { "Id", "Name", "NodeId", "TotalFloors" },
                values: new object[] { new Guid("ffffffff-0001-0000-0000-000000000000"), "Iron Depths", new Guid("bbbbbbbb-0009-0000-0000-000000000000"), 3 });

            migrationBuilder.InsertData(
                table: "MapEdges",
                columns: new[] { "Id", "DistanceKm", "FromNodeId", "IsBidirectional", "ToNodeId" },
                values: new object[,]
                {
                    { new Guid("cccccccc-0001-0000-0000-000000000000"), 5.0, new Guid("bbbbbbbb-0001-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0002-0000-0000-000000000000") },
                    { new Guid("cccccccc-0002-0000-0000-000000000000"), 2.5, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0013-0000-0000-000000000000") },
                    { new Guid("cccccccc-0003-0000-0000-000000000000"), 8.0, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0003-0000-0000-000000000000") },
                    { new Guid("cccccccc-0004-0000-0000-000000000000"), 6.0, new Guid("bbbbbbbb-0003-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0004-0000-0000-000000000000") },
                    { new Guid("cccccccc-0005-0000-0000-000000000000"), 12.0, new Guid("bbbbbbbb-0003-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0005-0000-0000-000000000000") },
                    { new Guid("cccccccc-0006-0000-0000-000000000000"), 3.5, new Guid("bbbbbbbb-0003-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0007-0000-0000-000000000000") },
                    { new Guid("cccccccc-0007-0000-0000-000000000000"), 7.0, new Guid("bbbbbbbb-0004-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0006-0000-0000-000000000000") },
                    { new Guid("cccccccc-0008-0000-0000-000000000000"), 5.0, new Guid("bbbbbbbb-0005-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0006-0000-0000-000000000000") },
                    { new Guid("cccccccc-0009-0000-0000-000000000000"), 13.0, new Guid("bbbbbbbb-0006-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0008-0000-0000-000000000000") },
                    { new Guid("cccccccc-0010-0000-0000-000000000000"), 3.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0009-0000-0000-000000000000") },
                    { new Guid("cccccccc-0011-0000-0000-000000000000"), 2.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0014-0000-0000-000000000000") },
                    { new Guid("cccccccc-0012-0000-0000-000000000000"), 10.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0010-0000-0000-000000000000") },
                    { new Guid("cccccccc-0013-0000-0000-000000000000"), 8.0, new Guid("bbbbbbbb-0010-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0011-0000-0000-000000000000") },
                    { new Guid("cccccccc-0014-0000-0000-000000000000"), 15.0, new Guid("bbbbbbbb-0005-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0012-0000-0000-000000000000") },
                    { new Guid("cccccccc-0015-0000-0000-000000000000"), 9.0, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0015-0000-0000-000000000000") },
                    { new Guid("cccccccc-0016-0000-0000-000000000000"), 4.0, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0016-0000-0000-000000000000") },
                    { new Guid("cccccccc-0017-0000-0000-000000000000"), 2.5, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0017-0000-0000-000000000000") }
                });

            migrationBuilder.InsertData(
                table: "CrossroadsPaths",
                columns: new[] { "Id", "AdditionalRequirement", "CrossroadsId", "Difficulty", "DistanceKm", "EstimatedDays", "LeadsToNodeId", "Name", "RewardXp" },
                values: new object[,]
                {
                    { new Guid("11111111-0101-0000-0000-000000000000"), null, new Guid("11111111-0001-0000-0000-000000000000"), "Easy", 6.0, 2, new Guid("bbbbbbbb-0004-0000-0000-000000000000"), "Valley Road", 600 },
                    { new Guid("11111111-0102-0000-0000-000000000000"), "2 gym sessions required", new Guid("11111111-0001-0000-0000-000000000000"), "Hard", 12.0, 5, new Guid("bbbbbbbb-0005-0000-0000-000000000000"), "Ruined Pass", 1400 },
                    { new Guid("11111111-0201-0000-0000-000000000000"), null, new Guid("11111111-0002-0000-0000-000000000000"), "Moderate", 8.0, 3, new Guid("bbbbbbbb-0011-0000-0000-000000000000"), "East Ridge", 900 },
                    { new Guid("11111111-0202-0000-0000-000000000000"), "3 gym sessions required", new Guid("11111111-0002-0000-0000-000000000000"), "Hard", 14.0, 6, new Guid("bbbbbbbb-0011-0000-0000-000000000000"), "North Face", 1800 }
                });

            migrationBuilder.InsertData(
                table: "DungeonFloors",
                columns: new[] { "Id", "DungeonPortalId", "FloorNumber", "RequiredActivity", "RequiredMinutes", "RewardXp" },
                values: new object[,]
                {
                    { new Guid("ffffffff-0101-0000-0000-000000000000"), new Guid("ffffffff-0001-0000-0000-000000000000"), 1, "Running", 30, 200 },
                    { new Guid("ffffffff-0102-0000-0000-000000000000"), new Guid("ffffffff-0001-0000-0000-000000000000"), 2, "Gym", 45, 350 },
                    { new Guid("ffffffff-0103-0000-0000-000000000000"), new Guid("ffffffff-0001-0000-0000-000000000000"), 3, "Cycling", 60, 500 }
                });
        }
    }
}

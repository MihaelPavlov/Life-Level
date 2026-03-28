using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMapSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MapNodes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    Region = table.Column<string>(type: "text", nullable: false),
                    PositionX = table.Column<float>(type: "real", nullable: false),
                    PositionY = table.Column<float>(type: "real", nullable: false),
                    LevelRequirement = table.Column<int>(type: "integer", nullable: false),
                    IsStartNode = table.Column<bool>(type: "boolean", nullable: false),
                    IsHidden = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MapNodes", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Bosses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    MaxHp = table.Column<int>(type: "integer", nullable: false),
                    RewardXp = table.Column<int>(type: "integer", nullable: false),
                    TimerDays = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bosses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Bosses_MapNodes_NodeId",
                        column: x => x.NodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Chests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Rarity = table.Column<string>(type: "text", nullable: false),
                    RewardXp = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Chests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Chests_MapNodes_NodeId",
                        column: x => x.NodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Crossroads",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NodeId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Crossroads", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Crossroads_MapNodes_NodeId",
                        column: x => x.NodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DungeonPortals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    TotalFloors = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DungeonPortals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DungeonPortals_MapNodes_NodeId",
                        column: x => x.NodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MapEdges",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FromNodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    ToNodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    IsBidirectional = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MapEdges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MapEdges_MapNodes_FromNodeId",
                        column: x => x.FromNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MapEdges_MapNodes_ToNodeId",
                        column: x => x.ToNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "CrossroadsPaths",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CrossroadsId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    Difficulty = table.Column<string>(type: "text", nullable: false),
                    EstimatedDays = table.Column<int>(type: "integer", nullable: false),
                    RewardXp = table.Column<int>(type: "integer", nullable: false),
                    AdditionalRequirement = table.Column<string>(type: "text", nullable: true),
                    LeadsToNodeId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CrossroadsPaths", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CrossroadsPaths_Crossroads_CrossroadsId",
                        column: x => x.CrossroadsId,
                        principalTable: "Crossroads",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CrossroadsPaths_MapNodes_LeadsToNodeId",
                        column: x => x.LeadsToNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DungeonFloors",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DungeonPortalId = table.Column<Guid>(type: "uuid", nullable: false),
                    FloorNumber = table.Column<int>(type: "integer", nullable: false),
                    RequiredActivity = table.Column<string>(type: "text", nullable: false),
                    RequiredMinutes = table.Column<int>(type: "integer", nullable: false),
                    RewardXp = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DungeonFloors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DungeonFloors_DungeonPortals_DungeonPortalId",
                        column: x => x.DungeonPortalId,
                        principalTable: "DungeonPortals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserMapProgresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CurrentNodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    CurrentEdgeId = table.Column<Guid>(type: "uuid", nullable: true),
                    DistanceTraveledOnEdge = table.Column<double>(type: "double precision", nullable: false),
                    DestinationNodeId = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserMapProgresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserMapProgresses_MapEdges_CurrentEdgeId",
                        column: x => x.CurrentEdgeId,
                        principalTable: "MapEdges",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserMapProgresses_MapNodes_CurrentNodeId",
                        column: x => x.CurrentNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserMapProgresses_MapNodes_DestinationNodeId",
                        column: x => x.DestinationNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserMapProgresses_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserBossStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    BossId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserMapProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    HpDealt = table.Column<int>(type: "integer", nullable: false),
                    IsDefeated = table.Column<bool>(type: "boolean", nullable: false),
                    DefeatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserBossStates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserBossStates_Bosses_BossId",
                        column: x => x.BossId,
                        principalTable: "Bosses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBossStates_UserMapProgresses_UserMapProgressId",
                        column: x => x.UserMapProgressId,
                        principalTable: "UserMapProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBossStates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserChestStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChestId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserMapProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsCollected = table.Column<bool>(type: "boolean", nullable: false),
                    CollectedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserChestStates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserChestStates_Chests_ChestId",
                        column: x => x.ChestId,
                        principalTable: "Chests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserChestStates_UserMapProgresses_UserMapProgressId",
                        column: x => x.UserMapProgressId,
                        principalTable: "UserMapProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserChestStates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserCrossroadsStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CrossroadsId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserMapProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChosenPathId = table.Column<Guid>(type: "uuid", nullable: true),
                    ChosenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserCrossroadsStates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserCrossroadsStates_CrossroadsPaths_ChosenPathId",
                        column: x => x.ChosenPathId,
                        principalTable: "CrossroadsPaths",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserCrossroadsStates_Crossroads_CrossroadsId",
                        column: x => x.CrossroadsId,
                        principalTable: "Crossroads",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserCrossroadsStates_UserMapProgresses_UserMapProgressId",
                        column: x => x.UserMapProgressId,
                        principalTable: "UserMapProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserCrossroadsStates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserDungeonStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DungeonPortalId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserMapProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsDiscovered = table.Column<bool>(type: "boolean", nullable: false),
                    CurrentFloor = table.Column<int>(type: "integer", nullable: false),
                    DiscoveredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserDungeonStates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserDungeonStates_DungeonPortals_DungeonPortalId",
                        column: x => x.DungeonPortalId,
                        principalTable: "DungeonPortals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserDungeonStates_UserMapProgresses_UserMapProgressId",
                        column: x => x.UserMapProgressId,
                        principalTable: "UserMapProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserDungeonStates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserNodeUnlocks",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    MapNodeId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserMapProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnlockedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserNodeUnlocks", x => new { x.UserId, x.MapNodeId });
                    table.ForeignKey(
                        name: "FK_UserNodeUnlocks_MapNodes_MapNodeId",
                        column: x => x.MapNodeId,
                        principalTable: "MapNodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserNodeUnlocks_UserMapProgresses_UserMapProgressId",
                        column: x => x.UserMapProgressId,
                        principalTable: "UserMapProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserNodeUnlocks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "MapNodes",
                columns: new[] { "Id", "Description", "Icon", "IsHidden", "IsStartNode", "LevelRequirement", "Name", "PositionX", "PositionY", "Region", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0001-0000-0000-000000000000"), "The starting point of every hero's journey.", "🏰", false, true, 1, "Ashfield Gate", 500f, 900f, "Ashfield", "Zone" },
                    { new Guid("bbbbbbbb-0002-0000-0000-000000000000"), "The edge of the Forest of Endurance. The trees grow thick here.", "🌲", false, false, 1, "Forest Entrance", 500f, 740f, "ForestOfEndurance", "Zone" },
                    { new Guid("bbbbbbbb-0003-0000-0000-000000000000"), "A massive oak splits the path. Choose wisely.", "⑂", false, false, 2, "Ancient Oak Crossroads", 480f, 600f, "ForestOfEndurance", "Crossroads" },
                    { new Guid("bbbbbbbb-0004-0000-0000-000000000000"), "A gentle valley winding through ancient trees.", "🌿", false, false, 2, "Valley Trail", 300f, 460f, "ForestOfEndurance", "Zone" },
                    { new Guid("bbbbbbbb-0005-0000-0000-000000000000"), "An old road through the ruins. Harder, but rewarding.", "🗿", false, false, 3, "Ruined Pass", 640f, 470f, "ForestOfEndurance", "Zone" },
                    { new Guid("bbbbbbbb-0006-0000-0000-000000000000"), "The ancient core of the forest, where the oldest trees stand.", "🌳", false, false, 5, "Forest Heart", 460f, 370f, "ForestOfEndurance", "Zone" },
                    { new Guid("bbbbbbbb-0007-0000-0000-000000000000"), "The Thornback Guardian defends the forest depths.", "💀", false, false, 3, "Thornback Lair", 310f, 530f, "ForestOfEndurance", "Boss" },
                    { new Guid("bbbbbbbb-0008-0000-0000-000000000000"), "The gateway to the Mountains of Strength.", "⛰️", false, false, 8, "Mountain Pass", 480f, 260f, "MountainsOfStrength", "Zone" },
                    { new Guid("bbbbbbbb-0009-0000-0000-000000000000"), "A shimmering portal leading to an ancient dungeon.", "🌀", false, false, 8, "Iron Depths Portal", 640f, 310f, "MountainsOfStrength", "Dungeon" },
                    { new Guid("bbbbbbbb-0010-0000-0000-000000000000"), "Two paths lead to the peak. One is treacherous.", "⑂", false, false, 10, "Summit Crossroads", 460f, 170f, "MountainsOfStrength", "Crossroads" },
                    { new Guid("bbbbbbbb-0011-0000-0000-000000000000"), "The summit. Only the strongest reach this place.", "🏔️", true, false, 12, "Peak of Strength", 350f, 80f, "MountainsOfStrength", "Zone" },
                    { new Guid("bbbbbbbb-0012-0000-0000-000000000000"), "The ocean breeze carries tales of balance and serenity.", "🌊", true, false, 10, "Coastal Road", 720f, 480f, "OceanOfBalance", "Zone" },
                    { new Guid("bbbbbbbb-0013-0000-0000-000000000000"), "A chest left by a traveler long ago.", "📦", false, false, 1, "Traveler's Cache", 620f, 680f, "ForestOfEndurance", "Chest" },
                    { new Guid("bbbbbbbb-0014-0000-0000-000000000000"), "A weathered chest at the mountain base.", "📦", false, false, 8, "Summit Cache", 370f, 300f, "MountainsOfStrength", "Chest" },
                    { new Guid("bbbbbbbb-0015-0000-0000-000000000000"), "The air grows heavy. Something stirs in the murk.", "🌫️", true, false, 6, "Swamp Edge", 650f, 700f, "Swamps", "Zone" }
                });

            migrationBuilder.InsertData(
                table: "Bosses",
                columns: new[] { "Id", "Icon", "MaxHp", "Name", "NodeId", "RewardXp", "TimerDays" },
                values: new object[] { new Guid("dddddddd-0001-0000-0000-000000000000"), "🦎", 500, "Thornback Guardian", new Guid("bbbbbbbb-0007-0000-0000-000000000000"), 800, 7 });

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
                    { new Guid("cccccccc-0006-0000-0000-000000000000"), 3.5, new Guid("bbbbbbbb-0003-0000-0000-000000000000"), false, new Guid("bbbbbbbb-0007-0000-0000-000000000000") },
                    { new Guid("cccccccc-0007-0000-0000-000000000000"), 7.0, new Guid("bbbbbbbb-0004-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0006-0000-0000-000000000000") },
                    { new Guid("cccccccc-0008-0000-0000-000000000000"), 5.0, new Guid("bbbbbbbb-0005-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0006-0000-0000-000000000000") },
                    { new Guid("cccccccc-0009-0000-0000-000000000000"), 13.0, new Guid("bbbbbbbb-0006-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0008-0000-0000-000000000000") },
                    { new Guid("cccccccc-0010-0000-0000-000000000000"), 3.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0009-0000-0000-000000000000") },
                    { new Guid("cccccccc-0011-0000-0000-000000000000"), 2.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0014-0000-0000-000000000000") },
                    { new Guid("cccccccc-0012-0000-0000-000000000000"), 10.0, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0010-0000-0000-000000000000") },
                    { new Guid("cccccccc-0013-0000-0000-000000000000"), 8.0, new Guid("bbbbbbbb-0010-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0011-0000-0000-000000000000") },
                    { new Guid("cccccccc-0014-0000-0000-000000000000"), 15.0, new Guid("bbbbbbbb-0005-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0012-0000-0000-000000000000") },
                    { new Guid("cccccccc-0015-0000-0000-000000000000"), 9.0, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0015-0000-0000-000000000000") }
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

            migrationBuilder.CreateIndex(
                name: "IX_Bosses_NodeId",
                table: "Bosses",
                column: "NodeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Chests_NodeId",
                table: "Chests",
                column: "NodeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Crossroads_NodeId",
                table: "Crossroads",
                column: "NodeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CrossroadsPaths_CrossroadsId",
                table: "CrossroadsPaths",
                column: "CrossroadsId");

            migrationBuilder.CreateIndex(
                name: "IX_CrossroadsPaths_LeadsToNodeId",
                table: "CrossroadsPaths",
                column: "LeadsToNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_DungeonFloors_DungeonPortalId",
                table: "DungeonFloors",
                column: "DungeonPortalId");

            migrationBuilder.CreateIndex(
                name: "IX_DungeonPortals_NodeId",
                table: "DungeonPortals",
                column: "NodeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MapEdges_FromNodeId",
                table: "MapEdges",
                column: "FromNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_MapEdges_ToNodeId",
                table: "MapEdges",
                column: "ToNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBossStates_BossId",
                table: "UserBossStates",
                column: "BossId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBossStates_UserId",
                table: "UserBossStates",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBossStates_UserMapProgressId",
                table: "UserBossStates",
                column: "UserMapProgressId");

            migrationBuilder.CreateIndex(
                name: "IX_UserChestStates_ChestId",
                table: "UserChestStates",
                column: "ChestId");

            migrationBuilder.CreateIndex(
                name: "IX_UserChestStates_UserId",
                table: "UserChestStates",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserChestStates_UserMapProgressId",
                table: "UserChestStates",
                column: "UserMapProgressId");

            migrationBuilder.CreateIndex(
                name: "IX_UserCrossroadsStates_ChosenPathId",
                table: "UserCrossroadsStates",
                column: "ChosenPathId");

            migrationBuilder.CreateIndex(
                name: "IX_UserCrossroadsStates_CrossroadsId",
                table: "UserCrossroadsStates",
                column: "CrossroadsId");

            migrationBuilder.CreateIndex(
                name: "IX_UserCrossroadsStates_UserId",
                table: "UserCrossroadsStates",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserCrossroadsStates_UserMapProgressId",
                table: "UserCrossroadsStates",
                column: "UserMapProgressId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDungeonStates_DungeonPortalId",
                table: "UserDungeonStates",
                column: "DungeonPortalId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDungeonStates_UserId",
                table: "UserDungeonStates",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDungeonStates_UserMapProgressId",
                table: "UserDungeonStates",
                column: "UserMapProgressId");

            migrationBuilder.CreateIndex(
                name: "IX_UserMapProgresses_CurrentEdgeId",
                table: "UserMapProgresses",
                column: "CurrentEdgeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserMapProgresses_CurrentNodeId",
                table: "UserMapProgresses",
                column: "CurrentNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserMapProgresses_DestinationNodeId",
                table: "UserMapProgresses",
                column: "DestinationNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserMapProgresses_UserId",
                table: "UserMapProgresses",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserNodeUnlocks_MapNodeId",
                table: "UserNodeUnlocks",
                column: "MapNodeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserNodeUnlocks_UserMapProgressId",
                table: "UserNodeUnlocks",
                column: "UserMapProgressId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DungeonFloors");

            migrationBuilder.DropTable(
                name: "UserBossStates");

            migrationBuilder.DropTable(
                name: "UserChestStates");

            migrationBuilder.DropTable(
                name: "UserCrossroadsStates");

            migrationBuilder.DropTable(
                name: "UserDungeonStates");

            migrationBuilder.DropTable(
                name: "UserNodeUnlocks");

            migrationBuilder.DropTable(
                name: "Bosses");

            migrationBuilder.DropTable(
                name: "Chests");

            migrationBuilder.DropTable(
                name: "CrossroadsPaths");

            migrationBuilder.DropTable(
                name: "DungeonPortals");

            migrationBuilder.DropTable(
                name: "UserMapProgresses");

            migrationBuilder.DropTable(
                name: "Crossroads");

            migrationBuilder.DropTable(
                name: "MapEdges");

            migrationBuilder.DropTable(
                name: "MapNodes");
        }
    }
}

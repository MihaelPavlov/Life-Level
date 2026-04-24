using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddChestZones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ChestRewardDescription",
                table: "WorldZones",
                type: "character varying(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChestRewardXp",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DungeonBonusXp",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserWorldChestStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorldZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    OpenedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserWorldChestStates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserWorldDungeonFloorStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FloorId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ProgressValue = table.Column<double>(type: "double precision", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserWorldDungeonFloorStates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserWorldDungeonStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorldZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CurrentFloorOrdinal = table.Column<int>(type: "integer", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FinishedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserWorldDungeonStates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WorldZoneDungeonFloors",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorldZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    Ordinal = table.Column<int>(type: "integer", nullable: false),
                    ActivityType = table.Column<int>(type: "integer", nullable: false),
                    TargetKind = table.Column<int>(type: "integer", nullable: false),
                    TargetValue = table.Column<double>(type: "double precision", nullable: false),
                    Name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Emoji = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorldZoneDungeonFloors", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldChestStates_UserId_WorldZoneId",
                table: "UserWorldChestStates",
                columns: new[] { "UserId", "WorldZoneId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldDungeonFloorStates_UserId_FloorId",
                table: "UserWorldDungeonFloorStates",
                columns: new[] { "UserId", "FloorId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldDungeonStates_UserId_WorldZoneId",
                table: "UserWorldDungeonStates",
                columns: new[] { "UserId", "WorldZoneId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WorldZoneDungeonFloors_WorldZoneId_Ordinal",
                table: "WorldZoneDungeonFloors",
                columns: new[] { "WorldZoneId", "Ordinal" },
                unique: true);

            // Wipe world-map data so WorldSeeder.SeedAsync reseeds the
            // expanded topology (chest + dungeon zones inserted into each
            // region's tier chain). Pre-launch only — safe because world-map
            // progress is the only thing wiped; character, XP, items, quests,
            // achievements, etc. all untouched.
            migrationBuilder.Sql(@"DELETE FROM ""UserWorldDungeonFloorStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserWorldDungeonStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserWorldChestStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""WorldZoneDungeonFloors"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserPathChoices"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserZoneUnlocks"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserWorldProgresses"";");
            // Legacy local-map user tables also FK to MapNodes; wipe before MapNodes.
            migrationBuilder.Sql(@"DELETE FROM ""UserBossStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserChestStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserDungeonStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserCrossroadsStates"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserNodeUnlocks"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserMapProgresses"";");
            migrationBuilder.Sql(@"DELETE FROM ""MapEdges"";");
            migrationBuilder.Sql(@"DELETE FROM ""MapNodes"";");
            migrationBuilder.Sql(@"DELETE FROM ""WorldZoneEdges"";");
            migrationBuilder.Sql(@"DELETE FROM ""WorldZones"";");
            migrationBuilder.Sql(@"DELETE FROM ""Regions"";");
            migrationBuilder.Sql(@"DELETE FROM ""Worlds"";");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserWorldChestStates");

            migrationBuilder.DropTable(
                name: "UserWorldDungeonFloorStates");

            migrationBuilder.DropTable(
                name: "UserWorldDungeonStates");

            migrationBuilder.DropTable(
                name: "WorldZoneDungeonFloors");

            migrationBuilder.DropColumn(
                name: "ChestRewardDescription",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "ChestRewardXp",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "DungeonBonusXp",
                table: "WorldZones");
        }
    }
}

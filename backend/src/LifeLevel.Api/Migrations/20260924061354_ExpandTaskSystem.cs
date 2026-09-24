using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class ExpandTaskSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DifficultyTier",
                table: "Quests",
                type: "text",
                nullable: false,
                defaultValue: "Standard");

            migrationBuilder.AddColumn<string>(
                name: "GroupKey",
                table: "Quests",
                type: "character varying(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ProgressMode",
                table: "Quests",
                type: "text",
                nullable: false,
                defaultValue: "Cumulative");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:any-duration-single", "SingleActivity" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:any-calories-single", "SingleActivity" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:running-distance", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:gym-duration-single", "SingleActivity" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:yoga-duration-single", "SingleActivity" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "daily:running-duration-single", "SingleActivity" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0010-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0011-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0012-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0101-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Workouts::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0102-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Workouts::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0103-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Duration::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0104-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Duration::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0105-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Calories::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0106-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Distance::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0107-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Distance::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0108-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Distance:Cycling:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0109-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Daily:Duration:Swimming:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0201-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Workouts::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0202-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Workouts::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0203-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0204-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0205-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0206-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Calories::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0207-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Calories::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0208-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Calories::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0209-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0210-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0211-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance::Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0212-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration:Yoga:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0213-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance:Cycling:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0214-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration:Swimming:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0215-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Duration:Climbing:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0216-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance:Hiking:Cumulative", "Cumulative" });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0217-0000-0000-000000000000"),
                columns: new[] { "DifficultyTier", "GroupKey", "ProgressMode" },
                values: new object[] { "Standard", "Weekly:Distance:Walking:Cumulative", "Cumulative" });

            migrationBuilder.InsertData(
                table: "Quests",
                columns: new[] { "Id", "Category", "Description", "DifficultyTier", "GroupKey", "IsActive", "ProgressMode", "RequiredActivity", "RewardXp", "SortOrder", "TargetUnit", "TargetValue", "Title", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0110-0000-0000-000000000000"), "ZonesCompleted", "Complete 1 zone today.", "Standard", "daily:zone", true, "Cumulative", null, 0L, 101, "zone", 1.0, "Pathfinder", "Daily" },
                    { new Guid("bbbbbbbb-0111-0000-0000-000000000000"), "ChestsOpened", "Open 1 available chest today.", "Standard", "daily:chest", true, "Cumulative", null, 0L, 102, "chest", 1.0, "Treasure Hunter", "Daily" },
                    { new Guid("bbbbbbbb-0112-0000-0000-000000000000"), "BossContributions", "Complete 1 workout while a boss is active.", "Standard", "daily:boss-contribution", true, "Cumulative", null, 0L, 103, "workout", 1.0, "Challenge the Boss", "Daily" },
                    { new Guid("bbbbbbbb-0113-0000-0000-000000000000"), "GuildRaidContributions", "Complete 1 workout while your guild raid is active.", "Standard", "daily:guild-contribution", true, "Cumulative", null, 0L, 104, "contribution", 1.0, "Answer the Call", "Daily" },
                    { new Guid("bbbbbbbb-0218-0000-0000-000000000000"), "ZonesCompleted", "Complete 1 zone this week.", "Easy", "weekly:zones", true, "Cumulative", null, 0L, 101, "zone", 1.0, "Trailblazer", "Weekly" },
                    { new Guid("bbbbbbbb-0219-0000-0000-000000000000"), "ZonesCompleted", "Complete 2 zones this week.", "Standard", "weekly:zones", true, "Cumulative", null, 0L, 102, "zones", 2.0, "Wayfinder", "Weekly" },
                    { new Guid("bbbbbbbb-0220-0000-0000-000000000000"), "ZonesCompleted", "Complete 3 zones this week.", "Stretch", "weekly:zones", true, "Cumulative", null, 0L, 103, "zones", 3.0, "Realm Walker", "Weekly" },
                    { new Guid("bbbbbbbb-0221-0000-0000-000000000000"), "ChestsOpened", "Open 1 reachable chest this week.", "Easy", "weekly:chests", true, "Cumulative", null, 0L, 104, "chest", 1.0, "Treasure Trail", "Weekly" },
                    { new Guid("bbbbbbbb-0222-0000-0000-000000000000"), "ChestsOpened", "Open 2 reachable chests this week.", "Stretch", "weekly:chests", true, "Cumulative", null, 0L, 105, "chests", 2.0, "Vault Seeker", "Weekly" },
                    { new Guid("bbbbbbbb-0223-0000-0000-000000000000"), "BossContributions", "Complete 2 workouts while a boss is active.", "Standard", "weekly:boss-contribution", true, "Cumulative", null, 0L, 106, "workouts", 2.0, "Press the Attack", "Weekly" },
                    { new Guid("bbbbbbbb-0224-0000-0000-000000000000"), "BossesDefeated", "Defeat 1 active boss this week.", "Standard", "weekly:boss-defeat", true, "Cumulative", null, 0L, 107, "boss", 1.0, "Boss Breaker", "Weekly" },
                    { new Guid("bbbbbbbb-0225-0000-0000-000000000000"), "GuildRaidContributions", "Contribute 2 workouts to the active guild raid.", "Standard", "weekly:guild-contribution", true, "Cumulative", null, 0L, 108, "contributions", 2.0, "Guild Vanguard", "Weekly" },
                    { new Guid("bbbbbbbb-0226-0000-0000-000000000000"), "GuildRaidsWon", "Contribute and help defeat 1 guild raid this week.", "Standard", "weekly:guild-victory", true, "Cumulative", null, 0L, 109, "victory", 1.0, "Victory Together", "Weekly" },
                    { new Guid("bbbbbbbb-0227-0000-0000-000000000000"), "RegionsCompleted", "Defeat your current region boss this week.", "Standard", "weekly:region", true, "Cumulative", null, 0L, 110, "region", 1.0, "Conquer the Region", "Weekly" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0110-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0111-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0112-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0113-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0218-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0219-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0220-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0221-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0222-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0223-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0224-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0225-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0226-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0227-0000-0000-000000000000"));

            migrationBuilder.DropColumn(
                name: "DifficultyTier",
                table: "Quests");

            migrationBuilder.DropColumn(
                name: "GroupKey",
                table: "Quests");

            migrationBuilder.DropColumn(
                name: "ProgressMode",
                table: "Quests");
        }
    }
}

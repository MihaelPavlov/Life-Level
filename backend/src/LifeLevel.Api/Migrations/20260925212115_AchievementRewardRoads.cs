using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AchievementRewardRoads : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ClaimedAt",
                table: "UserAchievements",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CoinReward",
                table: "Achievements",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "GemReward",
                table: "Achievements",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "UserAchievementStageChests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Category = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Tier = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    OpenedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ItemId = table.Column<Guid>(type: "uuid", nullable: true),
                    Coins = table.Column<int>(type: "integer", nullable: false),
                    Gems = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAchievementStageChests", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievementStageChests_UserId_Category_Tier",
                table: "UserAchievementStageChests",
                columns: new[] { "UserId", "Category", "Tier" },
                unique: true);

            // Achievements unlocked before Reward Roads already paid their XP on unlock,
            // so they count as claimed (no double XP). Coin/gem rewards are filled in by
            // AchievementSeeder on startup.
            migrationBuilder.Sql(
                "UPDATE \"UserAchievements\" SET \"ClaimedAt\" = \"UnlockedAt\" WHERE \"UnlockedAt\" IS NOT NULL;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserAchievementStageChests");

            migrationBuilder.DropColumn(
                name: "ClaimedAt",
                table: "UserAchievements");

            migrationBuilder.DropColumn(
                name: "CoinReward",
                table: "Achievements");

            migrationBuilder.DropColumn(
                name: "GemReward",
                table: "Achievements");
        }
    }
}

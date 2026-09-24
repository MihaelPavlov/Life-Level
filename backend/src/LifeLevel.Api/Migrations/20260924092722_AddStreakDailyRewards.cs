using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddStreakDailyRewards : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastRewardedStreakDate",
                table: "Streaks",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PendingRewardCoins",
                table: "Streaks",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            // Give existing players the reward for their latest completed
            // streak day without retroactively minting their entire history.
            migrationBuilder.Sql(
                """
                UPDATE "Streaks"
                SET "LastRewardedStreakDate" = "LastActivityDate",
                    "PendingRewardCoins" = "Current" * 10
                WHERE "LastActivityDate" IS NOT NULL AND "Current" > 0;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastRewardedStreakDate",
                table: "Streaks");

            migrationBuilder.DropColumn(
                name: "PendingRewardCoins",
                table: "Streaks");
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AccountWideSeenState : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastSeenTurnAt",
                table: "UserBossStates",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "LastSeenTurnId",
                table: "UserBossStates",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SeenAt",
                table: "UserAchievements",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SeenAt",
                table: "CharacterTitles",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastSeenTurnAt",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "LastSeenTurnId",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "SeenAt",
                table: "UserAchievements");

            migrationBuilder.DropColumn(
                name: "SeenAt",
                table: "CharacterTitles");
        }
    }
}

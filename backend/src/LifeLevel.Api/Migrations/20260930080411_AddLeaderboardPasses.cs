using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddLeaderboardPasses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LeaderboardPasses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PassedUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PassedUsername = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    PassedAvatarEmoji = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    WeekStartUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Coins = table.Column<int>(type: "integer", nullable: false),
                    Gems = table.Column<int>(type: "integer", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ClaimedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LeaderboardPasses", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LeaderboardWatches",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    WeekStartUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    AheadJson = table.Column<string>(type: "text", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LeaderboardWatches", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardPasses_UserId_ClaimedAtUtc",
                table: "LeaderboardPasses",
                columns: new[] { "UserId", "ClaimedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardPasses_UserId_PassedUserId_WeekStartUtc",
                table: "LeaderboardPasses",
                columns: new[] { "UserId", "PassedUserId", "WeekStartUtc" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardWatches_UserId",
                table: "LeaderboardWatches",
                column: "UserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LeaderboardPasses");

            migrationBuilder.DropTable(
                name: "LeaderboardWatches");
        }
    }
}

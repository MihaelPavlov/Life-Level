using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSeasonsModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Seasons",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Number = table.Column<int>(type: "integer", nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Theme = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    StartsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    State = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    XpPerTier = table.Column<int>(type: "integer", nullable: false),
                    TierCount = table.Column<int>(type: "integer", nullable: false),
                    MilestoneTier = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Seasons", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserFounderPasses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeasonId = table.Column<Guid>(type: "uuid", nullable: false),
                    AcquiredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Source = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserFounderPasses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserFounderPasses_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserSeasonClaims",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeasonId = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    Track = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ClaimedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    WasAutoGranted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserSeasonClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserSeasonClaims_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserSeasonProgresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeasonId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeasonXp = table.Column<long>(type: "bigint", nullable: false),
                    CurrentTier = table.Column<int>(type: "integer", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserSeasonProgresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserSeasonProgresses_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SeasonRewardTiers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SeasonId = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    Track = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RewardType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    RewardRefId = table.Column<Guid>(type: "uuid", nullable: true),
                    RewardKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: true),
                    Amount = table.Column<int>(type: "integer", nullable: false),
                    Label = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    IconKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Rarity = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SeasonRewardTiers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SeasonRewardTiers_Seasons_SeasonId",
                        column: x => x.SeasonId,
                        principalTable: "Seasons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SeasonRewardTiers_SeasonId_Tier_Track",
                table: "SeasonRewardTiers",
                columns: new[] { "SeasonId", "Tier", "Track" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Seasons_State",
                table: "Seasons",
                column: "State");

            migrationBuilder.CreateIndex(
                name: "IX_UserFounderPasses_UserId_SeasonId",
                table: "UserFounderPasses",
                columns: new[] { "UserId", "SeasonId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserSeasonClaims_UserId_SeasonId_Tier_Track",
                table: "UserSeasonClaims",
                columns: new[] { "UserId", "SeasonId", "Tier", "Track" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserSeasonProgresses_UserId_SeasonId",
                table: "UserSeasonProgresses",
                columns: new[] { "UserId", "SeasonId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SeasonRewardTiers");

            migrationBuilder.DropTable(
                name: "UserFounderPasses");

            migrationBuilder.DropTable(
                name: "UserSeasonClaims");

            migrationBuilder.DropTable(
                name: "UserSeasonProgresses");

            migrationBuilder.DropTable(
                name: "Seasons");
        }
    }
}

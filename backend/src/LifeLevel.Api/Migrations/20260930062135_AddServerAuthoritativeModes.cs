using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddServerAuthoritativeModes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "BurnChainRuns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndsAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndReason = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    LinksJson = table.Column<string>(type: "jsonb", nullable: false),
                    AcknowledgedLinks = table.Column<int>(type: "integer", nullable: false),
                    CoinsAwarded = table.Column<int>(type: "integer", nullable: false),
                    TalentCrystalsAwarded = table.Column<int>(type: "integer", nullable: false),
                    CollectedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BurnChainRuns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BurnChainRuns_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ModeRewardSettlements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Mode = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    RunId = table.Column<Guid>(type: "uuid", nullable: false),
                    Coins = table.Column<int>(type: "integer", nullable: false),
                    TalentCrystals = table.Column<int>(type: "integer", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ModeRewardSettlements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ModeRewardSettlements_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TreasureDelveRuns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    EntryDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StartedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Phase = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    EndReason = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Chamber = table.Column<int>(type: "integer", nullable: false),
                    FeaturedStat = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Strength = table.Column<int>(type: "integer", nullable: false),
                    Endurance = table.Column<int>(type: "integer", nullable: false),
                    Agility = table.Column<int>(type: "integer", nullable: false),
                    Flexibility = table.Column<int>(type: "integer", nullable: false),
                    Stamina = table.Column<int>(type: "integer", nullable: false),
                    SecuredCoins = table.Column<int>(type: "integer", nullable: false),
                    AtRiskCoins = table.Column<int>(type: "integer", nullable: false),
                    RoomsCleared = table.Column<int>(type: "integer", nullable: false),
                    OptionsJson = table.Column<string>(type: "jsonb", nullable: false),
                    ChosenPath = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    HistoryJson = table.Column<string>(type: "jsonb", nullable: false),
                    ItemsJson = table.Column<string>(type: "jsonb", nullable: false),
                    CoinsAwarded = table.Column<int>(type: "integer", nullable: false),
                    TalentCrystalsAwarded = table.Column<int>(type: "integer", nullable: false),
                    SettledAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AcknowledgedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TreasureDelveRuns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TreasureDelveRuns_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BurnChainRuns_UserId_StartedAtUtc",
                table: "BurnChainRuns",
                columns: new[] { "UserId", "StartedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_ModeRewardSettlements_Mode_RunId",
                table: "ModeRewardSettlements",
                columns: new[] { "Mode", "RunId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ModeRewardSettlements_UserId",
                table: "ModeRewardSettlements",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_TreasureDelveRuns_UserId_EntryDateUtc",
                table: "TreasureDelveRuns",
                columns: new[] { "UserId", "EntryDateUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BurnChainRuns");

            migrationBuilder.DropTable(
                name: "ModeRewardSettlements");

            migrationBuilder.DropTable(
                name: "TreasureDelveRuns");
        }
    }
}

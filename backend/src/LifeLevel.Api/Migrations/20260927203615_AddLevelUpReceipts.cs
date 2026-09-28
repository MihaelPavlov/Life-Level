using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddLevelUpReceipts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LevelUpReceipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Source = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    PreviousLevel = table.Column<int>(type: "integer", nullable: false),
                    NewLevel = table.Column<int>(type: "integer", nullable: false),
                    BaseStatPointsGranted = table.Column<int>(type: "integer", nullable: false),
                    BonusStatPointsGranted = table.Column<int>(type: "integer", nullable: false),
                    PowerGained = table.Column<int>(type: "integer", nullable: false),
                    CoinsGranted = table.Column<int>(type: "integer", nullable: false),
                    PreviousInventorySlots = table.Column<int>(type: "integer", nullable: false),
                    NewInventorySlots = table.Column<int>(type: "integer", nullable: false),
                    GrantedItemsJson = table.Column<string>(type: "text", nullable: false),
                    BlockedItemsJson = table.Column<string>(type: "text", nullable: false),
                    GrantedTitlesJson = table.Column<string>(type: "text", nullable: false),
                    AvailableAvatarsJson = table.Column<string>(type: "text", nullable: false),
                    AvailableRegionsJson = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FinalizedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AcknowledgedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LevelUpReceipts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LevelUpReceipts_UserId_AcknowledgedAt_CreatedAt",
                table: "LevelUpReceipts",
                columns: new[] { "UserId", "AcknowledgedAt", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LevelUpReceipts");
        }
    }
}

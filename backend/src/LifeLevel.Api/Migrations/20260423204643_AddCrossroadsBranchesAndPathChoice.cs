using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCrossroadsBranchesAndPathChoice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "BranchOfId",
                table: "WorldZones",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserPathChoices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CrossroadsZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChosenBranchZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChosenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPathChoices", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WorldZones_BranchOfId",
                table: "WorldZones",
                column: "BranchOfId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPathChoices_UserId_CrossroadsZoneId",
                table: "UserPathChoices",
                columns: new[] { "UserId", "CrossroadsZoneId" },
                unique: true);

            // Wipe world-map data so WorldSeeder.SeedAsync re-seeds the new
            // fork topology on next startup. Safe pre-launch: only world-map
            // progress is discarded — character / XP / inventory untouched.
            // Delete order honors FKs (leaf tables first).
            migrationBuilder.Sql(@"DELETE FROM ""UserPathChoices"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserZoneUnlocks"";");
            migrationBuilder.Sql(@"DELETE FROM ""UserWorldProgresses"";");
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
                name: "UserPathChoices");

            migrationBuilder.DropIndex(
                name: "IX_WorldZones_BranchOfId",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "BranchOfId",
                table: "WorldZones");
        }
    }
}

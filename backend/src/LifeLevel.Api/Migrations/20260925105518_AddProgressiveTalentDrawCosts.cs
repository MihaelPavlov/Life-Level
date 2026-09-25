using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddProgressiveTalentDrawCosts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CoinsSpent",
                table: "TalentDrawEntries",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CrystalsSpent",
                table: "TalentDrawEntries",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TalentPointsBeforeDraw",
                table: "TalentDrawEntries",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CoinsSpent",
                table: "TalentDrawEntries");

            migrationBuilder.DropColumn(
                name: "CrystalsSpent",
                table: "TalentDrawEntries");

            migrationBuilder.DropColumn(
                name: "TalentPointsBeforeDraw",
                table: "TalentDrawEntries");
        }
    }
}

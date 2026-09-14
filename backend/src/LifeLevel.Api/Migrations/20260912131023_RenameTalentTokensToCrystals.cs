using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class RenameTalentTokensToCrystals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Shards",
                table: "UserTalents");

            migrationBuilder.RenameColumn(
                name: "Tokens",
                table: "UserTalentWallets",
                newName: "Crystals");

            migrationBuilder.RenameColumn(
                name: "ShardsAwarded",
                table: "TalentDrawEntries",
                newName: "CrystalsAwarded");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Crystals",
                table: "UserTalentWallets",
                newName: "Tokens");

            migrationBuilder.RenameColumn(
                name: "CrystalsAwarded",
                table: "TalentDrawEntries",
                newName: "ShardsAwarded");

            migrationBuilder.AddColumn<int>(
                name: "Shards",
                table: "UserTalents",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }
    }
}

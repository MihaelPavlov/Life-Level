using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class SplitGemsAndTalentCrystals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Crystals",
                table: "UserTalentWallets",
                newName: "TalentCrystals");

            migrationBuilder.AddColumn<int>(
                name: "Gems",
                table: "UserTalentWallets",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            // Preserve the legacy balance in both newly independent currencies.
            migrationBuilder.Sql(
                "UPDATE \"UserTalentWallets\" SET \"Gems\" = \"TalentCrystals\"");

            migrationBuilder.AddColumn<int>(
                name: "TalentCrystalsGranted",
                table: "LevelUpReceipts",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Gems",
                table: "UserTalentWallets");

            migrationBuilder.DropColumn(
                name: "TalentCrystalsGranted",
                table: "LevelUpReceipts");

            migrationBuilder.RenameColumn(
                name: "TalentCrystals",
                table: "UserTalentWallets",
                newName: "Crystals");
        }
    }
}

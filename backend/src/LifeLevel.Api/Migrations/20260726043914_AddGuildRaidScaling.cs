using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddGuildRaidScaling : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "GuildSizeAtStart",
                table: "GuildRaids",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "MaxHp",
                table: "GuildRaids",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RewardXp",
                table: "GuildRaids",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GuildSizeAtStart",
                table: "GuildRaids");

            migrationBuilder.DropColumn(
                name: "MaxHp",
                table: "GuildRaids");

            migrationBuilder.DropColumn(
                name: "RewardXp",
                table: "GuildRaids");
        }
    }
}

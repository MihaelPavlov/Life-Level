using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddBossTimerToWorldZone : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "BossSuppressExpiry",
                table: "WorldZones",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BossTimerDays",
                table: "WorldZones",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BossSuppressExpiry",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "BossTimerDays",
                table: "WorldZones");
        }
    }
}

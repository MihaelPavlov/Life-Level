using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class WorldMapFinalRestructure : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_WorldZones_Worlds_WorldId",
                table: "WorldZones");

            migrationBuilder.DropIndex(
                name: "IX_WorldZones_WorldId",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "Icon",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "IsCrossroads",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "PositionX",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "PositionY",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "Region",
                table: "WorldZones");

            migrationBuilder.RenameColumn(
                name: "WorldId",
                table: "WorldZones",
                newName: "RegionId");

            migrationBuilder.RenameColumn(
                name: "TotalXp",
                table: "WorldZones",
                newName: "XpReward");

            migrationBuilder.RenameColumn(
                name: "TotalDistanceKm",
                table: "WorldZones",
                newName: "DistanceKm");

            migrationBuilder.RenameColumn(
                name: "IsHidden",
                table: "WorldZones",
                newName: "IsBoss");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "WorldZones",
                type: "character varying(128)",
                maxLength: 128,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "WorldZones",
                type: "character varying(512)",
                maxLength: 512,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Emoji",
                table: "WorldZones",
                type: "character varying(16)",
                maxLength: 16,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "LoreCollected",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LoreTotal",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "NodesCompleted",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "NodesTotal",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "WorldZones",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "CurrentRegionId",
                table: "UserWorldProgresses",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Regions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorldId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Emoji = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Theme = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    ChapterIndex = table.Column<int>(type: "integer", nullable: false),
                    LevelRequirement = table.Column<int>(type: "integer", nullable: false),
                    Lore = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    BossName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    BossStatus = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    DefaultStatus = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    PinsJson = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Regions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Regions_Worlds_WorldId",
                        column: x => x.WorldId,
                        principalTable: "Worlds",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WorldZones_RegionId_Tier",
                table: "WorldZones",
                columns: new[] { "RegionId", "Tier" });

            migrationBuilder.CreateIndex(
                name: "IX_Regions_WorldId_Name",
                table: "Regions",
                columns: new[] { "WorldId", "Name" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_WorldZones_Regions_RegionId",
                table: "WorldZones",
                column: "RegionId",
                principalTable: "Regions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_WorldZones_Regions_RegionId",
                table: "WorldZones");

            migrationBuilder.DropTable(
                name: "Regions");

            migrationBuilder.DropIndex(
                name: "IX_WorldZones_RegionId_Tier",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "Emoji",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "LoreCollected",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "LoreTotal",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "NodesCompleted",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "NodesTotal",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "CurrentRegionId",
                table: "UserWorldProgresses");

            migrationBuilder.RenameColumn(
                name: "XpReward",
                table: "WorldZones",
                newName: "TotalXp");

            migrationBuilder.RenameColumn(
                name: "RegionId",
                table: "WorldZones",
                newName: "WorldId");

            migrationBuilder.RenameColumn(
                name: "IsBoss",
                table: "WorldZones",
                newName: "IsHidden");

            migrationBuilder.RenameColumn(
                name: "DistanceKm",
                table: "WorldZones",
                newName: "TotalDistanceKm");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "WorldZones",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(128)",
                oldMaxLength: 128);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "WorldZones",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(512)",
                oldMaxLength: 512,
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Icon",
                table: "WorldZones",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "IsCrossroads",
                table: "WorldZones",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<float>(
                name: "PositionX",
                table: "WorldZones",
                type: "real",
                nullable: false,
                defaultValue: 0f);

            migrationBuilder.AddColumn<float>(
                name: "PositionY",
                table: "WorldZones",
                type: "real",
                nullable: false,
                defaultValue: 0f);

            migrationBuilder.AddColumn<string>(
                name: "Region",
                table: "WorldZones",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_WorldZones_WorldId",
                table: "WorldZones",
                column: "WorldId");

            migrationBuilder.AddForeignKey(
                name: "FK_WorldZones_Worlds_WorldId",
                table: "WorldZones",
                column: "WorldId",
                principalTable: "Worlds",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}

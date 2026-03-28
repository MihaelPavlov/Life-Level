using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMiniBosses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsMini",
                table: "Bosses",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.UpdateData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0001-0000-0000-000000000000"),
                column: "IsMini",
                value: false);

            migrationBuilder.InsertData(
                table: "MapNodes",
                columns: new[] { "Id", "Description", "Icon", "IsHidden", "IsStartNode", "LevelRequirement", "Name", "PositionX", "PositionY", "Region", "Type" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-0016-0000-0000-000000000000"), "Strange fungi pulse with an eerie glow. Something lurks within.", "🍄", false, false, 2, "Mushroom Grove", 700f, 640f, "ForestOfEndurance", "Boss" },
                    { new Guid("bbbbbbbb-0017-0000-0000-000000000000"), "Icy winds howl from the cave mouth. A predator has made its home here.", "❄️", false, false, 9, "Frost Cavern", 600f, 175f, "MountainsOfStrength", "Boss" }
                });

            migrationBuilder.InsertData(
                table: "Bosses",
                columns: new[] { "Id", "Icon", "IsMini", "MaxHp", "Name", "NodeId", "RewardXp", "TimerDays" },
                values: new object[,]
                {
                    { new Guid("dddddddd-0002-0000-0000-000000000000"), "🍄", true, 200, "Sporebloom Shroom", new Guid("bbbbbbbb-0016-0000-0000-000000000000"), 300, 3 },
                    { new Guid("dddddddd-0003-0000-0000-000000000000"), "❄️", true, 350, "Frost Stalker", new Guid("bbbbbbbb-0017-0000-0000-000000000000"), 500, 3 }
                });

            migrationBuilder.InsertData(
                table: "MapEdges",
                columns: new[] { "Id", "DistanceKm", "FromNodeId", "IsBidirectional", "ToNodeId" },
                values: new object[,]
                {
                    { new Guid("cccccccc-0016-0000-0000-000000000000"), 4.0, new Guid("bbbbbbbb-0002-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0016-0000-0000-000000000000") },
                    { new Guid("cccccccc-0017-0000-0000-000000000000"), 2.5, new Guid("bbbbbbbb-0008-0000-0000-000000000000"), true, new Guid("bbbbbbbb-0017-0000-0000-000000000000") }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0002-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "Bosses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-0003-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0016-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0017-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0016-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0017-0000-0000-000000000000"));

            migrationBuilder.DropColumn(
                name: "IsMini",
                table: "Bosses");
        }
    }
}

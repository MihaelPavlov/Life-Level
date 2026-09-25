using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class ClarifyWorldMapChestTaskText : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0111-0000-0000-000000000000"),
                column: "Description",
                value: "Open 1 chest on the World Map today.");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0221-0000-0000-000000000000"),
                column: "Description",
                value: "Open 1 chest on the World Map this week.");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0222-0000-0000-000000000000"),
                column: "Description",
                value: "Open 2 chests on the World Map this week.");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0111-0000-0000-000000000000"),
                column: "Description",
                value: "Open 1 available chest today.");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0221-0000-0000-000000000000"),
                column: "Description",
                value: "Open 1 reachable chest this week.");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0222-0000-0000-000000000000"),
                column: "Description",
                value: "Open 2 reachable chests this week.");
        }
    }
}

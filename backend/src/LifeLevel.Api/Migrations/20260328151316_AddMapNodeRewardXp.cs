using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMapNodeRewardXp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RewardXp",
                table: "MapNodes",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                column: "RewardXp",
                value: 0);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                column: "RewardXp",
                value: 100);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                column: "RewardXp",
                value: 150);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                column: "RewardXp",
                value: 150);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                column: "RewardXp",
                value: 200);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                column: "RewardXp",
                value: 300);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                column: "RewardXp",
                value: 200);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                column: "RewardXp",
                value: 450);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                column: "RewardXp",
                value: 450);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0010-0000-0000-000000000000"),
                column: "RewardXp",
                value: 600);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0011-0000-0000-000000000000"),
                column: "RewardXp",
                value: 800);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0012-0000-0000-000000000000"),
                column: "RewardXp",
                value: 600);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0013-0000-0000-000000000000"),
                column: "RewardXp",
                value: 100);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0014-0000-0000-000000000000"),
                column: "RewardXp",
                value: 450);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0015-0000-0000-000000000000"),
                column: "RewardXp",
                value: 350);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0016-0000-0000-000000000000"),
                column: "RewardXp",
                value: 150);

            migrationBuilder.UpdateData(
                table: "MapNodes",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0017-0000-0000-000000000000"),
                column: "RewardXp",
                value: 500);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RewardXp",
                table: "MapNodes");
        }
    }
}

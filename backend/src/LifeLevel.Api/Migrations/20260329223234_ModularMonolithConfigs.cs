using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class ModularMonolithConfigs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Role",
                table: "Users",
                type: "text",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<double>(
                name: "CurrentValue",
                table: "UserQuestProgress",
                type: "double precision",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric");

            migrationBuilder.AlterColumn<double>(
                name: "TargetValue",
                table: "Quests",
                type: "double precision",
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric",
                oldNullable: true);

            migrationBuilder.AlterColumn<long>(
                name: "RewardXp",
                table: "Quests",
                type: "bigint",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "Activities",
                type: "text",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 150L, 30.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 200L, 300.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 250L, 5.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 200L, 45.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 150L, 30.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 175L, 30.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 500L, 3.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 600L, 10.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 550L, 90.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0010-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 1000L, 10.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0011-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 1200L, 60.0 });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0012-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 2000L, 500.0 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "Role",
                table: "Users",
                type: "integer",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<decimal>(
                name: "CurrentValue",
                table: "UserQuestProgress",
                type: "numeric",
                nullable: false,
                oldClrType: typeof(double),
                oldType: "double precision");

            migrationBuilder.AlterColumn<decimal>(
                name: "TargetValue",
                table: "Quests",
                type: "numeric",
                nullable: true,
                oldClrType: typeof(double),
                oldType: "double precision",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "RewardXp",
                table: "Quests",
                type: "integer",
                nullable: false,
                oldClrType: typeof(long),
                oldType: "bigint");

            migrationBuilder.AlterColumn<int>(
                name: "Type",
                table: "Activities",
                type: "integer",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0001-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 150, 30m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0002-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 200, 300m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0003-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 250, 5m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0004-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 200, 45m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0005-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 150, 30m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0006-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 175, 30m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0007-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 500, 3m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0008-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 600, 10m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0009-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 550, 90m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0010-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 1000, 10m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0011-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 1200, 60m });

            migrationBuilder.UpdateData(
                table: "Quests",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-0012-0000-0000-000000000000"),
                columns: new[] { "RewardXp", "TargetValue" },
                values: new object[] { 2000, 500m });
        }
    }
}

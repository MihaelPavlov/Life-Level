using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class BridgeWorldZoneBoss : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bosses_MapNodes_NodeId",
                table: "Bosses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserBossStates_UserMapProgresses_UserMapProgressId",
                table: "UserBossStates");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserMapProgressId",
                table: "UserBossStates",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AlterColumn<Guid>(
                name: "NodeId",
                table: "Bosses",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<bool>(
                name: "SuppressExpiry",
                table: "Bosses",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "WorldZoneId",
                table: "Bosses",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bosses_WorldZoneId",
                table: "Bosses",
                column: "WorldZoneId");

            migrationBuilder.AddForeignKey(
                name: "FK_Bosses_MapNodes_NodeId",
                table: "Bosses",
                column: "NodeId",
                principalTable: "MapNodes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserBossStates_UserMapProgresses_UserMapProgressId",
                table: "UserBossStates",
                column: "UserMapProgressId",
                principalTable: "UserMapProgresses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bosses_MapNodes_NodeId",
                table: "Bosses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserBossStates_UserMapProgresses_UserMapProgressId",
                table: "UserBossStates");

            migrationBuilder.DropIndex(
                name: "IX_Bosses_WorldZoneId",
                table: "Bosses");

            migrationBuilder.DropColumn(
                name: "SuppressExpiry",
                table: "Bosses");

            migrationBuilder.DropColumn(
                name: "WorldZoneId",
                table: "Bosses");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserMapProgressId",
                table: "UserBossStates",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "NodeId",
                table: "Bosses",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Bosses_MapNodes_NodeId",
                table: "Bosses",
                column: "NodeId",
                principalTable: "MapNodes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserBossStates_UserMapProgresses_UserMapProgressId",
                table: "UserBossStates",
                column: "UserMapProgressId",
                principalTable: "UserMapProgresses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}

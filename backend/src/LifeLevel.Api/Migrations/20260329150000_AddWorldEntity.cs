using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorldEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Worlds",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Worlds", x => x.Id);
                });

            migrationBuilder.AddColumn<Guid>(
                name: "WorldId",
                table: "WorldZones",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "WorldId",
                table: "UserWorldProgresses",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_WorldZones_WorldId",
                table: "WorldZones",
                column: "WorldId");

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldProgresses_WorldId",
                table: "UserWorldProgresses",
                column: "WorldId");

            migrationBuilder.AddForeignKey(
                name: "FK_WorldZones_Worlds_WorldId",
                table: "WorldZones",
                column: "WorldId",
                principalTable: "Worlds",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_UserWorldProgresses_Worlds_WorldId",
                table: "UserWorldProgresses",
                column: "WorldId",
                principalTable: "Worlds",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_WorldZones_Worlds_WorldId",
                table: "WorldZones");

            migrationBuilder.DropForeignKey(
                name: "FK_UserWorldProgresses_Worlds_WorldId",
                table: "UserWorldProgresses");

            migrationBuilder.DropIndex(
                name: "IX_WorldZones_WorldId",
                table: "WorldZones");

            migrationBuilder.DropIndex(
                name: "IX_UserWorldProgresses_WorldId",
                table: "UserWorldProgresses");

            migrationBuilder.DropColumn(
                name: "WorldId",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "WorldId",
                table: "UserWorldProgresses");

            migrationBuilder.DropTable(
                name: "Worlds");
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddEncounterPinnedZones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "PinnedFromZoneId",
                table: "TrailEncounterTemplates",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PinnedToZoneId",
                table: "TrailEncounterTemplates",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PositionFraction",
                table: "TrailEncounterTemplates",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PinnedFromZoneId",
                table: "TrailEncounterTemplates");

            migrationBuilder.DropColumn(
                name: "PinnedToZoneId",
                table: "TrailEncounterTemplates");

            migrationBuilder.DropColumn(
                name: "PositionFraction",
                table: "TrailEncounterTemplates");
        }
    }
}

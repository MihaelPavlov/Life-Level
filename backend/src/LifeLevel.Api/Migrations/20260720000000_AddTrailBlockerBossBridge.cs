using System;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(AppDbContext))]
    [Migration("20260720000000_AddTrailBlockerBossBridge")]
    public partial class AddTrailBlockerBossBridge : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "TrailEncounterTemplateId",
                table: "Bosses",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bosses_TrailEncounterTemplateId",
                table: "Bosses",
                column: "TrailEncounterTemplateId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bosses_TrailEncounterTemplateId",
                table: "Bosses");

            migrationBuilder.DropColumn(
                name: "TrailEncounterTemplateId",
                table: "Bosses");
        }
    }
}

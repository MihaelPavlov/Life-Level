using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class DailyMaintenanceRun : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MaintenanceRuns",
                columns: table => new
                {
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    CompletedForUtcDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaintenanceRuns", x => new { x.Name, x.CompletedForUtcDate });
                });

            // Existing deployments already ran today's reset before this migration.
            migrationBuilder.Sql("""
                INSERT INTO "MaintenanceRuns" ("Name", "CompletedForUtcDate", "CompletedAtUtc")
                VALUES ('daily-reset', date_trunc('day', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC', now())
                ON CONFLICT DO NOTHING
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MaintenanceRuns");
        }
    }
}

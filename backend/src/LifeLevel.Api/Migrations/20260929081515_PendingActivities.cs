using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class PendingActivities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PendingActivities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Provider = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ExternalId = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ActivityType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    DurationMinutes = table.Column<int>(type: "integer", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: true),
                    Calories = table.Column<int>(type: "integer", nullable: true),
                    HeartRateAvg = table.Column<int>(type: "integer", nullable: true),
                    PerformedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    DuplicateOfId = table.Column<Guid>(type: "uuid", nullable: true),
                    ImportedActivityId = table.Column<Guid>(type: "uuid", nullable: true),
                    XpAwarded = table.Column<long>(type: "bigint", nullable: false),
                    ImportedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PendingActivities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PendingActivities_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PendingActivities_UserId_Provider_ExternalId",
                table: "PendingActivities",
                columns: new[] { "UserId", "Provider", "ExternalId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PendingActivities_UserId_Status",
                table: "PendingActivities",
                columns: new[] { "UserId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PendingActivities");
        }
    }
}

using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class RealStepCount : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Steps",
                table: "PendingActivities",
                type: "integer",
                nullable: true);

            // Steps used to be estimated from distance (distance x 1250, cycling
            // included), which double-counted runs already inside the phone's
            // daily step total. Only the daily step walks keep their steps.
            migrationBuilder.Sql(
                """UPDATE "Activities" SET "Steps" = 0 WHERE "ExternalId" IS NULL OR "ExternalId" NOT LIKE '%:steps:%';""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Steps",
                table: "PendingActivities");
        }
    }
}

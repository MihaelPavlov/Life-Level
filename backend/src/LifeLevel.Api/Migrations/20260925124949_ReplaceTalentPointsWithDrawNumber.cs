using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class ReplaceTalentPointsWithDrawNumber : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "TalentPointsBeforeDraw",
                table: "TalentDrawEntries",
                newName: "DrawNumber");

            migrationBuilder.Sql(
                """
                WITH ordered AS (
                    SELECT "Id",
                           ROW_NUMBER() OVER (
                               PARTITION BY "UserId"
                               ORDER BY "DrawnAt", "Id") AS "Number"
                    FROM "TalentDrawEntries"
                )
                UPDATE "TalentDrawEntries" AS entries
                SET "DrawNumber" = ordered."Number"
                FROM ordered
                WHERE entries."Id" = ordered."Id";
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "DrawNumber",
                table: "TalentDrawEntries",
                newName: "TalentPointsBeforeDraw");
        }
    }
}

using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class RankEnumToString : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Convert stored integer enum values to their string equivalents before changing the column type
            migrationBuilder.Sql("""
                ALTER TABLE "Characters"
                    ALTER COLUMN "Rank" TYPE text
                    USING CASE "Rank"
                        WHEN 0 THEN 'Novice'
                        WHEN 1 THEN 'Warrior'
                        WHEN 2 THEN 'Veteran'
                        WHEN 3 THEN 'Champion'
                        WHEN 4 THEN 'Legend'
                        ELSE 'Novice'
                    END;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                ALTER TABLE "Characters"
                    ALTER COLUMN "Rank" TYPE integer
                    USING CASE "Rank"
                        WHEN 'Novice'   THEN 0
                        WHEN 'Warrior'  THEN 1
                        WHEN 'Veteran'  THEN 2
                        WHEN 'Champion' THEN 3
                        WHEN 'Legend'   THEN 4
                        ELSE 0
                    END;
                """);
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddLevelTitleGrants : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LevelStatBonuses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false),
                    BonusPoints = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LevelStatBonuses", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LevelTitleGrants",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false),
                    TitleId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LevelTitleGrants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LevelTitleGrants_Titles_TitleId",
                        column: x => x.TitleId,
                        principalTable: "Titles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RankThresholds",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Rank = table.Column<string>(type: "text", nullable: false),
                    BossesRequired = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RankThresholds", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LevelStatBonuses_Level",
                table: "LevelStatBonuses",
                column: "Level",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LevelTitleGrants_Level_TitleId",
                table: "LevelTitleGrants",
                columns: new[] { "Level", "TitleId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LevelTitleGrants_TitleId",
                table: "LevelTitleGrants",
                column: "TitleId");

            migrationBuilder.CreateIndex(
                name: "IX_RankThresholds_Rank",
                table: "RankThresholds",
                column: "Rank",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LevelStatBonuses");

            migrationBuilder.DropTable(
                name: "LevelTitleGrants");

            migrationBuilder.DropTable(
                name: "RankThresholds");
        }
    }
}

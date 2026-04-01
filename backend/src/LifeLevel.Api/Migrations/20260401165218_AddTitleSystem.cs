using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTitleSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "EquippedTitleId",
                table: "Characters",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Titles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Emoji = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    UnlockCondition = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UnlockCriteria = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Titles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CharacterTitles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CharacterId = table.Column<Guid>(type: "uuid", nullable: false),
                    TitleId = table.Column<Guid>(type: "uuid", nullable: false),
                    EarnedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CharacterTitles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CharacterTitles_Characters_CharacterId",
                        column: x => x.CharacterId,
                        principalTable: "Characters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CharacterTitles_Titles_TitleId",
                        column: x => x.TitleId,
                        principalTable: "Titles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Characters_EquippedTitleId",
                table: "Characters",
                column: "EquippedTitleId");

            migrationBuilder.CreateIndex(
                name: "IX_CharacterTitles_CharacterId_TitleId",
                table: "CharacterTitles",
                columns: new[] { "CharacterId", "TitleId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CharacterTitles_TitleId",
                table: "CharacterTitles",
                column: "TitleId");

            migrationBuilder.AddForeignKey(
                name: "FK_Characters_Titles_EquippedTitleId",
                table: "Characters",
                column: "EquippedTitleId",
                principalTable: "Titles",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Characters_Titles_EquippedTitleId",
                table: "Characters");

            migrationBuilder.DropTable(
                name: "CharacterTitles");

            migrationBuilder.DropTable(
                name: "Titles");

            migrationBuilder.DropIndex(
                name: "IX_Characters_EquippedTitleId",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "EquippedTitleId",
                table: "Characters");
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCharacterSetup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AvatarEmoji",
                table: "Characters",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ClassId",
                table: "Characters",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsSetupComplete",
                table: "Characters",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "CharacterClasses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Emoji = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Tagline = table.Column<string>(type: "text", nullable: false),
                    StrMultiplier = table.Column<float>(type: "real", nullable: false),
                    EndMultiplier = table.Column<float>(type: "real", nullable: false),
                    AgiMultiplier = table.Column<float>(type: "real", nullable: false),
                    FlxMultiplier = table.Column<float>(type: "real", nullable: false),
                    StaMultiplier = table.Column<float>(type: "real", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CharacterClasses", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "CharacterClasses",
                columns: new[] { "Id", "AgiMultiplier", "Description", "Emoji", "EndMultiplier", "FlxMultiplier", "IsActive", "Name", "StaMultiplier", "StrMultiplier", "Tagline" },
                values: new object[,]
                {
                    { new Guid("aaaaaaaa-0001-0000-0000-000000000000"), 1f, "Master of raw power. Gym sessions and heavy lifts are your domain.", "⚔️", 1f, 1f, true, "Warrior", 1.2f, 1.3f, "Lift heavy. Hit harder." },
                    { new Guid("aaaaaaaa-0002-0000-0000-000000000000"), 1.2f, "Born to endure the long road. Running and cycling are your strengths.", "🏹", 1.3f, 1f, true, "Ranger", 1f, 1f, "Run far. Run fast." },
                    { new Guid("aaaaaaaa-0003-0000-0000-000000000000"), 1f, "Seeker of balance and flow. Yoga and flexibility training are your path.", "🧘", 1f, 1.4f, true, "Mystic", 1.2f, 1f, "Bend. Don't break." },
                    { new Guid("aaaaaaaa-0004-0000-0000-000000000000"), 1f, "Immovable. Unstoppable. All-round athlete with iron stamina.", "🛡️", 1.1f, 1f, true, "Sentinel", 1.4f, 1f, "Outlast everything." }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Characters_ClassId",
                table: "Characters",
                column: "ClassId");

            migrationBuilder.CreateIndex(
                name: "IX_CharacterClasses_Name",
                table: "CharacterClasses",
                column: "Name",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Characters_CharacterClasses_ClassId",
                table: "Characters",
                column: "ClassId",
                principalTable: "CharacterClasses",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Characters_CharacterClasses_ClassId",
                table: "Characters");

            migrationBuilder.DropTable(
                name: "CharacterClasses");

            migrationBuilder.DropIndex(
                name: "IX_Characters_ClassId",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "AvatarEmoji",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "ClassId",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "IsSetupComplete",
                table: "Characters");
        }
    }
}

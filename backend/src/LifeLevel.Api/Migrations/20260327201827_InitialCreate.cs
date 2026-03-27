using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Username = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Characters",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false),
                    Xp = table.Column<long>(type: "bigint", nullable: false),
                    Rank = table.Column<int>(type: "integer", nullable: false),
                    Strength = table.Column<int>(type: "integer", nullable: false),
                    Endurance = table.Column<int>(type: "integer", nullable: false),
                    Agility = table.Column<int>(type: "integer", nullable: false),
                    Flexibility = table.Column<int>(type: "integer", nullable: false),
                    Stamina = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Characters", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Characters_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Activities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CharacterId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    DurationMinutes = table.Column<int>(type: "integer", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    Calories = table.Column<int>(type: "integer", nullable: false),
                    HeartRateAvg = table.Column<int>(type: "integer", nullable: true),
                    XpGained = table.Column<long>(type: "bigint", nullable: false),
                    StrGained = table.Column<int>(type: "integer", nullable: false),
                    EndGained = table.Column<int>(type: "integer", nullable: false),
                    AgiGained = table.Column<int>(type: "integer", nullable: false),
                    FlxGained = table.Column<int>(type: "integer", nullable: false),
                    StaGained = table.Column<int>(type: "integer", nullable: false),
                    LoggedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Activities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Activities_Characters_CharacterId",
                        column: x => x.CharacterId,
                        principalTable: "Characters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Activities_CharacterId",
                table: "Activities",
                column: "CharacterId");

            migrationBuilder.CreateIndex(
                name: "IX_Characters_UserId",
                table: "Characters",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Activities");

            migrationBuilder.DropTable(
                name: "Characters");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}

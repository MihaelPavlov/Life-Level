using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddTalentsModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "TalentDrawEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DrawnAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Kind = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    TalentId = table.Column<Guid>(type: "uuid", nullable: false),
                    ShardsAwarded = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TalentDrawEntries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TalentDrawEntries_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Talents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Description = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    IconKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Rarity = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    EffectType = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    PerLevelValue = table.Column<double>(type: "double precision", nullable: false),
                    MaxLevel = table.Column<int>(type: "integer", nullable: false),
                    DrawWeight = table.Column<int>(type: "integer", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Talents", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserTalentWallets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Coins = table.Column<long>(type: "bigint", nullable: false),
                    Tokens = table.Column<int>(type: "integer", nullable: false),
                    SecondWindUsedThisWeek = table.Column<int>(type: "integer", nullable: false),
                    SecondWindWeekKey = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: true),
                    LastStreakBrokenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserTalentWallets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserTalentWallets_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserTalents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    TalentId = table.Column<Guid>(type: "uuid", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false),
                    Shards = table.Column<int>(type: "integer", nullable: false),
                    UnlockedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserTalents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserTalents_Talents_TalentId",
                        column: x => x.TalentId,
                        principalTable: "Talents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserTalents_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TalentDrawEntries_UserId_DrawnAt",
                table: "TalentDrawEntries",
                columns: new[] { "UserId", "DrawnAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Talents_Key",
                table: "Talents",
                column: "Key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTalents_TalentId",
                table: "UserTalents",
                column: "TalentId");

            migrationBuilder.CreateIndex(
                name: "IX_UserTalents_UserId_TalentId",
                table: "UserTalents",
                columns: new[] { "UserId", "TalentId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserTalentWallets_UserId",
                table: "UserTalentWallets",
                column: "UserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TalentDrawEntries");

            migrationBuilder.DropTable(
                name: "UserTalents");

            migrationBuilder.DropTable(
                name: "UserTalentWallets");

            migrationBuilder.DropTable(
                name: "Talents");
        }
    }
}

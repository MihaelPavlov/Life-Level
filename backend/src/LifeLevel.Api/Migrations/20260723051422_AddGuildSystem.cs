using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddGuildSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Guilds",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Description = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: false),
                    Icon = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    OwnerUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    MaxMembers = table.Column<int>(type: "integer", nullable: false),
                    IsOpen = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Guilds", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Guilds_Users_OwnerUserId",
                        column: x => x.OwnerUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "GuildMembers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GuildId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuildMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GuildMembers_Guilds_GuildId",
                        column: x => x.GuildId,
                        principalTable: "Guilds",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GuildMembers_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GuildRaids",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GuildId = table.Column<Guid>(type: "uuid", nullable: false),
                    BossId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TotalDamage = table.Column<int>(type: "integer", nullable: false),
                    IsDefeated = table.Column<bool>(type: "boolean", nullable: false),
                    IsExpired = table.Column<bool>(type: "boolean", nullable: false),
                    DefeatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RewardClaimedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuildRaids", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GuildRaids_Bosses_BossId",
                        column: x => x.BossId,
                        principalTable: "Bosses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_GuildRaids_Guilds_GuildId",
                        column: x => x.GuildId,
                        principalTable: "Guilds",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GuildRaidContributions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GuildRaidId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DamageDealt = table.Column<int>(type: "integer", nullable: false),
                    LastActivityId = table.Column<Guid>(type: "uuid", nullable: true),
                    LastActivityAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuildRaidContributions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GuildRaidContributions_GuildRaids_GuildRaidId",
                        column: x => x.GuildRaidId,
                        principalTable: "GuildRaids",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GuildRaidContributions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_GuildMembers_GuildId_UserId",
                table: "GuildMembers",
                columns: new[] { "GuildId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GuildMembers_UserId",
                table: "GuildMembers",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaidContributions_GuildRaidId_UserId",
                table: "GuildRaidContributions",
                columns: new[] { "GuildRaidId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaidContributions_UserId",
                table: "GuildRaidContributions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaids_BossId",
                table: "GuildRaids",
                column: "BossId");

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaids_GuildId_IsDefeated_IsExpired",
                table: "GuildRaids",
                columns: new[] { "GuildId", "IsDefeated", "IsExpired" });

            migrationBuilder.CreateIndex(
                name: "IX_Guilds_Name",
                table: "Guilds",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_Guilds_OwnerUserId",
                table: "Guilds",
                column: "OwnerUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "GuildMembers");

            migrationBuilder.DropTable(
                name: "GuildRaidContributions");

            migrationBuilder.DropTable(
                name: "GuildRaids");

            migrationBuilder.DropTable(
                name: "Guilds");
        }
    }
}

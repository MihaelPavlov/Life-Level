using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddGuildRaidExpiryAcknowledgements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "GuildRaidExpiryAcknowledgements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GuildRaidId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    AcknowledgedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuildRaidExpiryAcknowledgements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GuildRaidExpiryAcknowledgements_GuildRaids_GuildRaidId",
                        column: x => x.GuildRaidId,
                        principalTable: "GuildRaids",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GuildRaidExpiryAcknowledgements_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaidExpiryAcknowledgements_GuildRaidId_UserId",
                table: "GuildRaidExpiryAcknowledgements",
                columns: new[] { "GuildRaidId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_GuildRaidExpiryAcknowledgements_UserId",
                table: "GuildRaidExpiryAcknowledgements",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "GuildRaidExpiryAcknowledgements");
        }
    }
}

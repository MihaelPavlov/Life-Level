using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddIntegrationsModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Activities_CharacterId",
                table: "Activities");

            migrationBuilder.AddColumn<string>(
                name: "ExternalId",
                table: "Activities",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ExternalActivityRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CharacterId = table.Column<Guid>(type: "uuid", nullable: false),
                    Provider = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ExternalId = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ActivityStartTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    WasImported = table.Column<bool>(type: "boolean", nullable: false),
                    ImportedActivityId = table.Column<Guid>(type: "uuid", nullable: true),
                    SyncedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExternalActivityRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExternalActivityRecords_Characters_CharacterId",
                        column: x => x.CharacterId,
                        principalTable: "Characters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Activities_CharacterId_ExternalId",
                table: "Activities",
                columns: new[] { "CharacterId", "ExternalId" },
                unique: true,
                filter: "\"ExternalId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ExternalActivityRecords_CharacterId_Provider_ExternalId",
                table: "ExternalActivityRecords",
                columns: new[] { "CharacterId", "Provider", "ExternalId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExternalActivityRecords");

            migrationBuilder.DropIndex(
                name: "IX_Activities_CharacterId_ExternalId",
                table: "Activities");

            migrationBuilder.DropColumn(
                name: "ExternalId",
                table: "Activities");

            migrationBuilder.CreateIndex(
                name: "IX_Activities_CharacterId",
                table: "Activities",
                column: "CharacterId");
        }
    }
}

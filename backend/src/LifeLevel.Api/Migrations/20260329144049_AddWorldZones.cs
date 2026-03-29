using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorldZones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "WorldZoneId",
                table: "MapNodes",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "WorldZones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    Region = table.Column<string>(type: "text", nullable: false),
                    Tier = table.Column<int>(type: "integer", nullable: false),
                    PositionX = table.Column<float>(type: "real", nullable: false),
                    PositionY = table.Column<float>(type: "real", nullable: false),
                    LevelRequirement = table.Column<int>(type: "integer", nullable: false),
                    TotalXp = table.Column<int>(type: "integer", nullable: false),
                    TotalDistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    IsCrossroads = table.Column<bool>(type: "boolean", nullable: false),
                    IsStartZone = table.Column<bool>(type: "boolean", nullable: false),
                    IsHidden = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorldZones", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WorldZoneEdges",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FromZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    ToZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    IsBidirectional = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorldZoneEdges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorldZoneEdges_WorldZones_FromZoneId",
                        column: x => x.FromZoneId,
                        principalTable: "WorldZones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WorldZoneEdges_WorldZones_ToZoneId",
                        column: x => x.ToZoneId,
                        principalTable: "WorldZones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserWorldProgresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CurrentZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    CurrentEdgeId = table.Column<Guid>(type: "uuid", nullable: true),
                    DistanceTraveledOnEdge = table.Column<double>(type: "double precision", nullable: false),
                    DestinationZoneId = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserWorldProgresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserWorldProgresses_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserWorldProgresses_WorldZoneEdges_CurrentEdgeId",
                        column: x => x.CurrentEdgeId,
                        principalTable: "WorldZoneEdges",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserWorldProgresses_WorldZones_CurrentZoneId",
                        column: x => x.CurrentZoneId,
                        principalTable: "WorldZones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserWorldProgresses_WorldZones_DestinationZoneId",
                        column: x => x.DestinationZoneId,
                        principalTable: "WorldZones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserZoneUnlocks",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    WorldZoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserWorldProgressId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnlockedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserZoneUnlocks", x => new { x.UserId, x.WorldZoneId });
                    table.ForeignKey(
                        name: "FK_UserZoneUnlocks_UserWorldProgresses_UserWorldProgressId",
                        column: x => x.UserWorldProgressId,
                        principalTable: "UserWorldProgresses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserZoneUnlocks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserZoneUnlocks_WorldZones_WorldZoneId",
                        column: x => x.WorldZoneId,
                        principalTable: "WorldZones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MapNodes_WorldZoneId",
                table: "MapNodes",
                column: "WorldZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldProgresses_CurrentEdgeId",
                table: "UserWorldProgresses",
                column: "CurrentEdgeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldProgresses_CurrentZoneId",
                table: "UserWorldProgresses",
                column: "CurrentZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldProgresses_DestinationZoneId",
                table: "UserWorldProgresses",
                column: "DestinationZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_UserWorldProgresses_UserId",
                table: "UserWorldProgresses",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserZoneUnlocks_UserWorldProgressId",
                table: "UserZoneUnlocks",
                column: "UserWorldProgressId");

            migrationBuilder.CreateIndex(
                name: "IX_UserZoneUnlocks_WorldZoneId",
                table: "UserZoneUnlocks",
                column: "WorldZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_WorldZoneEdges_FromZoneId",
                table: "WorldZoneEdges",
                column: "FromZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_WorldZoneEdges_ToZoneId",
                table: "WorldZoneEdges",
                column: "ToZoneId");

            migrationBuilder.AddForeignKey(
                name: "FK_MapNodes_WorldZones_WorldZoneId",
                table: "MapNodes",
                column: "WorldZoneId",
                principalTable: "WorldZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MapNodes_WorldZones_WorldZoneId",
                table: "MapNodes");

            migrationBuilder.DropTable(
                name: "UserZoneUnlocks");

            migrationBuilder.DropTable(
                name: "UserWorldProgresses");

            migrationBuilder.DropTable(
                name: "WorldZoneEdges");

            migrationBuilder.DropTable(
                name: "WorldZones");

            migrationBuilder.DropIndex(
                name: "IX_MapNodes_WorldZoneId",
                table: "MapNodes");

            migrationBuilder.DropColumn(
                name: "WorldZoneId",
                table: "MapNodes");
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class MakeBossEdgeBidirectional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0006-0000-0000-000000000000"),
                column: "IsBidirectional",
                value: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "MapEdges",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-0006-0000-0000-000000000000"),
                column: "IsBidirectional",
                value: false);
        }
    }
}

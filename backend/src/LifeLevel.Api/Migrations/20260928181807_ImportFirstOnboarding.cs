using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class ImportFirstOnboarding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TraitKey",
                table: "Characters",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsHybrid",
                table: "CharacterClasses",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.UpdateData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0001-0000-0000-000000000000"),
                column: "IsHybrid",
                value: false);

            migrationBuilder.UpdateData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0002-0000-0000-000000000000"),
                column: "IsHybrid",
                value: false);

            migrationBuilder.UpdateData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0003-0000-0000-000000000000"),
                column: "IsHybrid",
                value: false);

            migrationBuilder.UpdateData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0004-0000-0000-000000000000"),
                column: "IsHybrid",
                value: false);

            migrationBuilder.InsertData(
                table: "CharacterClasses",
                columns: new[] { "Id", "AgiMultiplier", "Description", "Emoji", "EndMultiplier", "FlxMultiplier", "IsActive", "IsHybrid", "Name", "StaMultiplier", "StrMultiplier", "Tagline" },
                values: new object[,]
                {
                    { new Guid("aaaaaaaa-0005-0000-0000-000000000000"), 1f, "At home in the water. Swimming builds your endurance and calm.", "🌊", 1.2f, 1.1f, true, false, "Tidecaller", 1.2f, 1f, "Own the water." },
                    { new Guid("aaaaaaaa-0006-0000-0000-000000000000"), 1.2f, "Born on the rock. Climbing trains your grip, pull and balance.", "🧗", 1f, 1.1f, true, false, "Cragborn", 1f, 1.2f, "Grip, pull, rise." },
                    { new Guid("aaaaaaaa-0007-0000-0000-000000000000"), 1f, "Long days on foot. Hikes and walks carry you across the world.", "🥾", 1.2f, 1f, true, false, "Wayfarer", 1.3f, 1f, "Every trail, every day." },
                    { new Guid("aaaaaaaa-0008-0000-0000-000000000000"), 1f, "Hybrid of Ranger and Warrior. You run and lift in the same week.", "⚜️", 1.2f, 1f, true, true, "Vanguard", 1.1f, 1.2f, "Run it, then lift it." },
                    { new Guid("aaaaaaaa-0009-0000-0000-000000000000"), 1.1f, "Hybrid of Warrior and Mystic. Strength with flow.", "🗡️", 1f, 1.2f, true, true, "Spellblade", 1f, 1.2f, "Strength with flow." },
                    { new Guid("aaaaaaaa-0010-0000-0000-000000000000"), 1f, "Hybrid of Ranger and Mystic. Trails outside, stretch after.", "🌿", 1.2f, 1.3f, true, true, "Druid", 1f, 1f, "Trails and stretch." },
                    { new Guid("aaaaaaaa-0011-0000-0000-000000000000"), 1f, "The multisport athlete. Swim, bike and run all feed your hero.", "⚡", 1.3f, 1f, true, true, "Stormrunner", 1.2f, 1f, "Swim, bike, run." }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0005-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0006-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0007-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0008-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0009-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0010-0000-0000-000000000000"));

            migrationBuilder.DeleteData(
                table: "CharacterClasses",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-0011-0000-0000-000000000000"));

            migrationBuilder.DropColumn(
                name: "TraitKey",
                table: "Characters");

            migrationBuilder.DropColumn(
                name: "IsHybrid",
                table: "CharacterClasses");
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddBossCombatV2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserBossStates_UserId",
                table: "UserBossStates");

            migrationBuilder.AddColumn<int>(
                name: "BossArmor",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BossCounterattackDamage",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BossMaxHp",
                table: "WorldZones",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ArmorSnapshot",
                table: "UserBossStates",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CombatVersion",
                table: "UserBossStates",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CounterattackDamageSnapshot",
                table: "UserBossStates",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CurrentPlayerHp",
                table: "UserBossStates",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsTargeted",
                table: "UserBossStates",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "MaxHpSnapshot",
                table: "UserBossStates",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "RecoveryEndsAt",
                table: "UserBossStates",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Armor",
                table: "GuildRaids",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Armor",
                table: "Bosses",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CombatVersion",
                table: "Bosses",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CounterattackDamage",
                table: "Bosses",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "BossCombatTurns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserBossStateId = table.Column<Guid>(type: "uuid", nullable: false),
                    ActivityId = table.Column<Guid>(type: "uuid", nullable: false),
                    ActivityType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    DurationMinutes = table.Column<int>(type: "integer", nullable: false),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    Calories = table.Column<int>(type: "integer", nullable: false),
                    RawWorkoutDamage = table.Column<int>(type: "integer", nullable: false),
                    Attack = table.Column<int>(type: "integer", nullable: false),
                    Defense = table.Column<int>(type: "integer", nullable: false),
                    Health = table.Column<int>(type: "integer", nullable: false),
                    Power = table.Column<int>(type: "integer", nullable: false),
                    DamageMultiplier = table.Column<double>(type: "double precision", nullable: false),
                    BossActiveDamagePct = table.Column<double>(type: "double precision", nullable: false),
                    BossArmor = table.Column<int>(type: "integer", nullable: false),
                    BossMitigation = table.Column<double>(type: "double precision", nullable: false),
                    DamageDealt = table.Column<int>(type: "integer", nullable: false),
                    BossHpAfter = table.Column<int>(type: "integer", nullable: false),
                    BossCounterattackRaw = table.Column<int>(type: "integer", nullable: false),
                    PlayerMitigation = table.Column<double>(type: "double precision", nullable: false),
                    DamageTaken = table.Column<int>(type: "integer", nullable: false),
                    PlayerHpAfter = table.Column<int>(type: "integer", nullable: false),
                    BossDefeated = table.Column<bool>(type: "boolean", nullable: false),
                    PlayerDefeated = table.Column<bool>(type: "boolean", nullable: false),
                    SkipReason = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    OccurredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BossCombatTurns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BossCombatTurns_UserBossStates_UserBossStateId",
                        column: x => x.UserBossStateId,
                        principalTable: "UserBossStates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // Backfill the 15 deterministic world bosses from the same
            // target-turn balance model used by new seeds. World bosses no
            // longer expire.
            migrationBuilder.Sql("""
                UPDATE "WorldZones" AS z
                SET "BossMaxHp" = v.max_hp,
                    "BossArmor" = v.armor,
                    "BossCounterattackDamage" = v.counterattack,
                    "BossTimerDays" = 0,
                    "BossSuppressExpiry" = TRUE
                FROM "Regions" AS r
                JOIN (VALUES
                    (1,1824,10,7),(2,1984,15,16),(3,2120,20,24),
                    (4,2320,25,37),(5,3050,30,53),(6,3140,35,65),
                    (7,3240,40,75),(8,3330,45,88),(9,3410,50,102),
                    (10,3480,55,116),(11,4272,60,151),(12,4296,65,163),
                    (13,4320,70,177),(14,4344,75,187),(15,4380,80,203)
                ) AS v(chapter, max_hp, armor, counterattack)
                  ON v.chapter = r."ChapterIndex"
                WHERE z."RegionId" = r."Id" AND z."IsBoss" = TRUE;
                """);

            // Upgrade active world fights while preserving the percentage of
            // HP already removed. Other/legacy fights retain their old HP.
            migrationBuilder.Sql("""
                UPDATE "UserBossStates" AS s
                SET "HpDealt" = LEAST(w."BossMaxHp",
                        ROUND(s."HpDealt"::numeric / GREATEST(1, b."MaxHp") * w."BossMaxHp")::integer),
                    "MaxHpSnapshot" = w."BossMaxHp",
                    "ArmorSnapshot" = w."BossArmor",
                    "CounterattackDamageSnapshot" = w."BossCounterattackDamage",
                    "CurrentPlayerHp" = 50,
                    "CombatVersion" = 2
                FROM "Bosses" AS b
                JOIN "WorldZones" AS w ON w."Id" = b."WorldZoneId"
                WHERE s."BossId" = b."Id" AND s."IsDefeated" = FALSE;

                UPDATE "UserBossStates" AS s
                SET "MaxHpSnapshot" = b."MaxHp",
                    "ArmorSnapshot" = b."Armor",
                    "CounterattackDamageSnapshot" = b."CounterattackDamage",
                    "CurrentPlayerHp" = 50,
                    "CombatVersion" = 2
                FROM "Bosses" AS b
                WHERE s."BossId" = b."Id" AND s."MaxHpSnapshot" = 0;

                UPDATE "Bosses" AS b
                SET "MaxHp" = w."BossMaxHp",
                    "Armor" = w."BossArmor",
                    "CounterattackDamage" = w."BossCounterattackDamage",
                    "CombatVersion" = 2,
                    "TimerDays" = 0,
                    "SuppressExpiry" = TRUE
                FROM "WorldZones" AS w
                WHERE b."WorldZoneId" = w."Id" AND w."BossMaxHp" IS NOT NULL;

                UPDATE "GuildRaids" AS r
                SET "Armor" = b."Armor"
                FROM "Bosses" AS b
                WHERE r."BossId" = b."Id";

                WITH ranked AS (
                    SELECT "Id",
                           ROW_NUMBER() OVER (
                               PARTITION BY "UserId"
                               ORDER BY "StartedAt" DESC NULLS LAST, "Id") AS rn
                    FROM "UserBossStates"
                    WHERE "IsDefeated" = FALSE AND "IsExpired" = FALSE
                          AND "StartedAt" IS NOT NULL
                )
                UPDATE "UserBossStates" AS s
                SET "IsTargeted" = (ranked.rn = 1)
                FROM ranked
                WHERE s."Id" = ranked."Id";
                """);

            migrationBuilder.CreateIndex(
                name: "IX_UserBossStates_UserId",
                table: "UserBossStates",
                column: "UserId",
                unique: true,
                filter: "\"IsTargeted\" = TRUE");

            migrationBuilder.CreateIndex(
                name: "IX_BossCombatTurns_UserBossStateId_ActivityId",
                table: "BossCombatTurns",
                columns: new[] { "UserBossStateId", "ActivityId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BossCombatTurns");

            migrationBuilder.DropIndex(
                name: "IX_UserBossStates_UserId",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "BossArmor",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "BossCounterattackDamage",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "BossMaxHp",
                table: "WorldZones");

            migrationBuilder.DropColumn(
                name: "ArmorSnapshot",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "CombatVersion",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "CounterattackDamageSnapshot",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "CurrentPlayerHp",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "IsTargeted",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "MaxHpSnapshot",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "RecoveryEndsAt",
                table: "UserBossStates");

            migrationBuilder.DropColumn(
                name: "Armor",
                table: "GuildRaids");

            migrationBuilder.DropColumn(
                name: "Armor",
                table: "Bosses");

            migrationBuilder.DropColumn(
                name: "CombatVersion",
                table: "Bosses");

            migrationBuilder.DropColumn(
                name: "CounterattackDamage",
                table: "Bosses");

            migrationBuilder.CreateIndex(
                name: "IX_UserBossStates_UserId",
                table: "UserBossStates",
                column: "UserId");
        }
    }
}

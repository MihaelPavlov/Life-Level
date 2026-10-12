using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LifeLevel.Api.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261012110000_FirstTwoBossesThreeWorkouts")]
public sealed class FirstTwoBossesThreeWorkouts : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        Rebalance(migrationBuilder,
            ("aa00010b-0000-0000-0000-000000000000", 912, 684),
            ("aa000209-0000-0000-0000-000000000000", 1240, 744));

    protected override void Down(MigrationBuilder migrationBuilder) =>
        Rebalance(migrationBuilder,
            ("aa00010b-0000-0000-0000-000000000000", 684, 912),
            ("aa000209-0000-0000-0000-000000000000", 744, 1240));

    private static void Rebalance(
        MigrationBuilder migrationBuilder,
        params (string ZoneId, int OldHp, int NewHp)[] targets)
    {
        var values = string.Join(",\n", targets.Select(t =>
            $"('{t.ZoneId}'::uuid, {t.OldHp}, {t.NewHp})"));

        migrationBuilder.Sql($"""
            WITH targets(zone_id, old_hp, new_hp) AS (
                VALUES {values}
            ), changed_zones AS (
                UPDATE "WorldZones" AS z
                SET "BossMaxHp" = t.new_hp
                FROM targets AS t
                WHERE z."Id" = t.zone_id
                  AND z."IsBoss" = TRUE
                  AND z."BossMaxHp" = t.old_hp
                  AND NOT EXISTS (
                      SELECT 1 FROM "Bosses" AS existing
                      WHERE existing."WorldZoneId" = z."Id"
                        AND existing."MaxHp" <> t.old_hp
                  )
                RETURNING z."Id"
            ), changed_bosses AS (
                UPDATE "Bosses" AS b
                SET "MaxHp" = t.new_hp
                FROM changed_zones AS z
                JOIN targets AS t ON t.zone_id = z."Id"
                WHERE b."WorldZoneId" = z."Id"
                  AND b."MaxHp" = t.old_hp
                RETURNING b."Id", b."MaxHp"
            )
            UPDATE "UserBossStates" AS s
            SET "HpDealt" = LEAST(b."MaxHp", GREATEST(0,
                    ROUND(s."HpDealt"::numeric /
                        GREATEST(1, COALESCE(NULLIF(s."MaxHpSnapshot", 0), t.old_hp))
                        * b."MaxHp")::integer)),
                "MaxHpSnapshot" = b."MaxHp"
            FROM changed_bosses AS b
            JOIN "Bosses" AS boss ON boss."Id" = b."Id"
            JOIN targets AS t ON t.zone_id = boss."WorldZoneId"
            WHERE s."BossId" = b."Id"
              AND s."IsDefeated" = FALSE;
            """);
    }
}

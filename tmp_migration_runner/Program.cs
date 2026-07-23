using Npgsql;

var connectionString = "Host=localhost;Database=lifelevel;Username=postgres;Password=1qaz!QAZ";
var mode = args.FirstOrDefault() ?? "list";

await using var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();

if (mode == "insert-trail-encounters")
{
    await using var insert = conn.CreateCommand();
    insert.CommandText = """
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    SELECT '20260527165116_AddTrailEncounterTemplates', '9.0.3'
    WHERE NOT EXISTS (
        SELECT 1
        FROM "__EFMigrationsHistory"
        WHERE "MigrationId" = '20260527165116_AddTrailEncounterTemplates'
    );
    """;
    var changed = await insert.ExecuteNonQueryAsync();
    Console.WriteLine($"InsertedRows={changed}");
    return;
}

if (mode == "apply-map-tutorial")
{
    await using var alter = conn.CreateCommand();
    alter.CommandText = """
    ALTER TABLE "Characters"
    ADD COLUMN IF NOT EXISTS "MapTutorialStep" integer NOT NULL DEFAULT 0;
    """;
    await alter.ExecuteNonQueryAsync();

    await using var insert = conn.CreateCommand();
    insert.CommandText = """
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    SELECT '20260712000000_AddMapTutorialProgress', '9.0.3'
    WHERE NOT EXISTS (
        SELECT 1
        FROM "__EFMigrationsHistory"
        WHERE "MigrationId" = '20260712000000_AddMapTutorialProgress'
    );
    """;
    var changed = await insert.ExecuteNonQueryAsync();
    Console.WriteLine($"MapTutorialMigrationHistoryInserted={changed}");
    return;
}

await using var cmd = conn.CreateCommand();
cmd.CommandText = """
SELECT "MigrationId", "ProductVersion"
FROM "__EFMigrationsHistory"
ORDER BY "MigrationId";
""";

await using var reader = await cmd.ExecuteReaderAsync();
while (await reader.ReadAsync())
{
    Console.WriteLine($"{reader.GetString(0)}|{reader.GetString(1)}");
}

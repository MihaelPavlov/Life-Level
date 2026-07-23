using Npgsql;

var connectionString = "Host=localhost;Database=lifelevel;Username=postgres;Password=1qaz!QAZ";

await using var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();

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

using Npgsql;

namespace LifeLevel.Api.Application.BackgroundJobs;

/// <summary>Holds a transaction-scoped lock on a dedicated connection for the work.</summary>
public sealed class PostgresJobLock(IConfiguration configuration)
{
    public async Task<bool> TryRunAsync(long key, Func<Task> work, CancellationToken ct)
    {
        await using var connection = await OpenAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        await using var command = new NpgsqlCommand("SELECT pg_try_advisory_xact_lock(@key)", connection, transaction);
        command.Parameters.AddWithValue("key", key);
        if (await command.ExecuteScalarAsync(ct) is not true) return false;
        await work();
        await transaction.CommitAsync(ct);
        return true;
    }

    public async Task RunExclusiveAsync(long key, Func<Task> work, CancellationToken ct)
    {
        await using var connection = await OpenAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);
        await using var command = new NpgsqlCommand("SELECT pg_advisory_xact_lock(@key)", connection, transaction);
        command.Parameters.AddWithValue("key", key);
        await command.ExecuteNonQueryAsync(ct);
        await work();
        await transaction.CommitAsync(ct);
    }

    private async Task<NpgsqlConnection> OpenAsync(CancellationToken ct)
    {
        var connection = new NpgsqlConnection(configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync(ct);
        return connection;
    }

}

using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>Releases queued hints only after EF commits an explicit transaction.</summary>
public sealed class StateChangeTransactionInterceptor : DbTransactionInterceptor
{
    public override Task TransactionCommittedAsync(DbTransaction transaction,
        TransactionEndEventData eventData, CancellationToken cancellationToken = default) =>
        eventData.Context is AppDbContext db
            ? db.FlushStateChangesAsync(cancellationToken)
            : Task.CompletedTask;

    public override void TransactionCommitted(DbTransaction transaction, TransactionEndEventData eventData)
    {
        if (eventData.Context is AppDbContext db)
            db.FlushStateChangesAsync(CancellationToken.None).GetAwaiter().GetResult();
    }

    public override Task TransactionRolledBackAsync(DbTransaction transaction,
        TransactionEndEventData eventData, CancellationToken cancellationToken = default)
    {
        if (eventData.Context is AppDbContext db) db.ClearStateChanges();
        return Task.CompletedTask;
    }

    public override void TransactionRolledBack(DbTransaction transaction, TransactionEndEventData eventData)
    {
        if (eventData.Context is AppDbContext db) db.ClearStateChanges();
    }
}

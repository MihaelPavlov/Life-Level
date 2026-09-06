namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Maintenance port for season lifecycle: closes any <c>Active</c> season whose
/// <c>EndsAt</c> has passed (auto-granting every reached-but-unclaimed tier) and
/// promotes the next <c>Scheduled</c> season to <c>Active</c>.
///
/// Implemented by the Seasons module; driven by <c>SeasonRolloverJob</c> and the
/// admin "restart" endpoint. Mirrors <see cref="IGuildRaidMaintenancePort"/>.
/// </summary>
public interface ISeasonRolloverPort
{
    /// <summary>Rolls over every due season. Returns the number of seasons closed.</summary>
    Task<int> RolloverDueSeasonsAsync(CancellationToken ct = default);
}

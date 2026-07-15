namespace LifeLevel.Modules.WorldZone.Application.UseCases;

/// Deterministic encounter placement — same edge + template always produce the same result.
/// Used by both MapReadService (display) and WorldZoneService (movement intercept).
internal static class TrailEncounterHelper
{
    /// <summary>
    /// Returns (spawns, t) where t ∈ [0.25, 0.75] is the position along the edge.
    ///
    /// If the template is pinned to specific zones (fromZone/toZone), only the matching
    /// edge spawns the encounter (always, regardless of spawnChance). If a fixedPosition
    /// is stored on the template, that overrides the seed-based random position.
    ///
    /// When neither pinning nor fixed position is set, falls back to the original
    /// seed-based logic so existing encounters are unaffected.
    /// </summary>
    public static (bool Spawns, double T) ComputeEncounterSlot(
        Guid edgeId,
        Guid templateId,
        double spawnChance,
        Guid edgeFromZoneId  = default,
        Guid edgeToZoneId    = default,
        Guid? pinnedFromZone = null,
        Guid? pinnedToZone   = null,
        double? fixedPosition = null)
    {
        bool isPinned = pinnedFromZone.HasValue || pinnedToZone.HasValue;

        if (isPinned)
        {
            // Pinned encounters only appear on the single matching edge.
            bool fromOk = !pinnedFromZone.HasValue
                || pinnedFromZone.Value == edgeFromZoneId
                || pinnedFromZone.Value == edgeToZoneId;
            bool toOk = !pinnedToZone.HasValue
                || pinnedToZone.Value == edgeToZoneId
                || pinnedToZone.Value == edgeFromZoneId;

            if (!fromOk || !toOk) return (false, 0);

            // Always spawn on the correct edge; use fixed position or seed midpoint.
            var t = fixedPosition ?? ComputePositionOnly(edgeId, templateId);
            return (true, t);
        }

        // ── Original seed-based logic (backward-compatible) ──────────────────
        var edgeBytes = edgeId.ToByteArray();
        var tplBytes  = templateId.ToByteArray();
        var seed = BitConverter.ToInt32(edgeBytes, 0)
                 ^ BitConverter.ToInt32(tplBytes,  0)
                 ^ BitConverter.ToInt32(edgeBytes, 4)
                 ^ BitConverter.ToInt32(tplBytes,  4);
        var rng = new Random(seed);
        var spawns = rng.NextDouble() < spawnChance;
        var tPos = fixedPosition ?? (0.25 + rng.NextDouble() * 0.50);
        return (spawns, tPos);
    }

    // Seed-based position without consuming the spawn-check slot (used for pinned edges).
    private static double ComputePositionOnly(Guid edgeId, Guid templateId)
    {
        var edgeBytes = edgeId.ToByteArray();
        var tplBytes  = templateId.ToByteArray();
        var seed = BitConverter.ToInt32(edgeBytes, 0)
                 ^ BitConverter.ToInt32(tplBytes,  0)
                 ^ BitConverter.ToInt32(edgeBytes, 4)
                 ^ BitConverter.ToInt32(tplBytes,  4);
        var rng = new Random(seed);
        return 0.25 + rng.NextDouble() * 0.50;
    }
}
